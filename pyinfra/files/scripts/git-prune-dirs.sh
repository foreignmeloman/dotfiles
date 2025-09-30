#!/usr/bin/env bash
# git-prune-dirs: Remove all empty directories from the repository

set -euo pipefail

# Get the root of the git repository
repo_root=$(git rev-parse --show-toplevel)

find "$repo_root" -type d -empty -not -path "$repo_root/.git/*" -exec rm -rvf {} +
