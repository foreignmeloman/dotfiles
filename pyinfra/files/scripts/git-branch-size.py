#!/usr/bin/env python3

import argparse
import copy
import json
import subprocess
import sys
import multiprocessing as mp


def get_blob_size(blob: str) -> int:
    try:
        output = int(
            subprocess.run(
                ['git', 'cat-file', '-s', blob],
                capture_output=True,
                check=True,
            )
            .stdout.decode()
            .strip()
        )
    except subprocess.CalledProcessError:
        output = 0
    return output


def get_commit_stats(sha: str) -> dict:
    output_rows = (
        subprocess.run(
            [
                'git',
                'diff-tree',
                '-r',
                '-c',
                '-M',
                '-C',
                '--no-commit-id',
                sha,
            ],
            capture_output=True,
            check=True,
        )
        .stdout.decode()
        .strip()
        .split('\n')
    )

    # A hack for the initial commit
    if output_rows == ['']:
        lstree_rows = (
            subprocess.run(
                ['git', 'ls-tree', '-r', sha],
                capture_output=True,
                check=True,
            )
            .stdout.decode()
            .strip()
            .split('\n')
        )

        output_rows = [
            f'x x x {r.split()[2]} A {r.split()[3]}'
            for r in lstree_rows
            if r.split()[1] == 'blob'
        ]

    commit = {
        'sha': sha,
        'files': [],
        'total_size': 0,
    }
    for row in output_rows:
        row_data = row.split()
        previous_blob = row_data[2]
        current_blob = row_data[3]
        change_type = row_data[4]
        file_name = row_data[5]
        if change_type == 'D':
            continue
        if change_type.startswith(('R', 'C')) and previous_blob == current_blob:
            file_name = row_data[6]
            commit['files'].append(
                [
                    file_name,
                    0,
                    change_type,
                ]
            )
            continue

        blob_size = get_blob_size(current_blob)
        commit['files'].append(
            [
                file_name,
                blob_size,
                change_type,
            ]
        )
        commit['total_size'] += blob_size
    commit['files'] = sorted(
        commit['files'],
        key=lambda x: x[1],
        reverse=True,
    )
    return commit


def get_commit_list_stats(commit_list: list, sort: bool = True) -> dict:
    with mp.Pool() as pool:
        commit_stats = pool.map(get_commit_stats, commit_list)

    if sort:
        commit_stats = sorted(
            commit_stats,
            key=lambda x: x['total_size'],
            reverse=True,
        )
    return {
        'total_size': sum(c['total_size'] for c in commit_stats),
        'commits': commit_stats,
    }


def get_topic_stats(
    base_branch: str,
    topic_branch: str,
    sort: bool = True,
) -> dict:
    output_rows = (
        subprocess.run(
            ['git', 'cherry', base_branch, topic_branch],
            capture_output=True,
            check=True,
        )
        .stdout.decode()
        .strip()
        .split('\n')
    )

    return get_commit_list_stats(
        [sha.split()[1] for sha in output_rows],
        sort,
    )


def get_branch_stats(branch_name: str, sort: bool = True) -> dict:
    output_rows = (
        subprocess.run(
            ['git', 'log', '--no-merges', '--pretty=%H', branch_name],
            capture_output=True,
            check=True,
        )
        .stdout.decode()
        .strip()
        .split('\n')
    )
    return get_commit_list_stats(
        output_rows,
        sort,
    )


def append_added_stats(stats: dict, top: int):
    total_added_size = 0
    all_added_files = []
    for commit in stats['commits']:
        added_files = copy.deepcopy(
            list(filter(lambda x: x[2] == 'A', commit['files']))
        )
        for f in added_files:
            total_added_size += f[1]
            f.append(commit['sha'])
        all_added_files.extend(added_files)
    quantity = len(all_added_files)
    limit = min(top, quantity)
    top_added = sorted(
        all_added_files,
        key=lambda x: x[1],
        reverse=True,
    )[0:limit]
    stats['added_stats'] = {
        'top_added': top_added,
        'total_added_size': total_added_size,
    }


def verify_branch(name: str):
    try:
        subprocess.run(
            ['git', 'rev-parse', '--verify', name],
            capture_output=True,
            check=True,
        )
    except subprocess.CalledProcessError:
        print(
            f'ERROR: Branch named "{name}" not found.',
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--max-added', type=int)
    parser.add_argument('--max-total', type=int)
    parser.add_argument('--top-n-added', type=int, default=10)
    sub_parsers = parser.add_subparsers(dest='command')

    parser_commit = sub_parsers.add_parser('commit')
    parser_commit.add_argument('sha', type=str)

    parser_topic = sub_parsers.add_parser('topic')
    parser_topic.add_argument('base_branch', type=str)
    parser_topic.add_argument('topic_branch', type=str)

    parser_topic = sub_parsers.add_parser('branch')
    parser_topic.add_argument('branch_name', type=str)

    args = parser.parse_args()

    result = {}
    if args.command == 'commit':
        result = get_commit_list_stats([args.sha])
        append_added_stats(result, args.top_n_added)
    elif args.command == 'topic':
        verify_branch(args.base_branch)
        verify_branch(args.topic_branch)
        result = get_topic_stats(args.base_branch, args.topic_branch)
        append_added_stats(result, args.top_n_added)
    elif args.command == 'branch':
        verify_branch(args.branch_name)
        result = get_branch_stats(args.branch_name)
        append_added_stats(result, args.top_n_added)

    print(json.dumps(result, indent=2), flush=True)

    total_added = result['added_stats']['total_added_size']
    if args.max_added and total_added > args.max_added:
        print(
            f'ERROR: Total added size of {total_added} bytes '
            f'is greater than max allowed {args.max_added} bytes',
            file=sys.stderr,
        )
        sys.exit(1)

    total_size = result['total_size']
    if args.max_total and total_size > args.max_total:
        print(
            f'ERROR: Total size of {total_size} bytes '
            f'is greater than max allowed {args.max_total} bytes',
            file=sys.stderr,
        )
        sys.exit(1)
