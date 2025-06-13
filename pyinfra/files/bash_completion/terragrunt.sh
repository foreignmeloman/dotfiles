_terragrunt_completion() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    function _words_contains {
        local list="${2:-${words[@]}}"
        echo "$list"|grep -Eoq "(^| )$1"
    }

    # Main Terragrunt commands
    local commands="backend exec run stack catalog scaffold find fd list ls dag hcl info render"
    local bakend_subcommands="bootstrap delete migrate"
    local run_subcommands="plan apply destroy init validate import output state show refresh taint untaint force-unlock"
    local hcl_subcommands="format fmt validate"
    local dag_subcommands="graph"

    # Global flags
    local global_flags="--experiment --experiment-mode --log-custom-format --log-disable --log-format --log-level --log-show-abs-paths --no-color --non-interactive --strict-control --strict-mode --working-dir --help -h --version -v"

    # Command-specific flags
    local apply_flags="-auto-approve -backup -compact-warnings -destroy -lock -lock-timeout -input=true -no-color -parallelism -state -state-out -var -var-file"
    local backend_bootstrap_flags="--all -a --config --download-dir"
    local backend_delete_flags="--all -a --config --download-dir --force"
    local backend_migrate_flags="--config --download-dir --force"
    local dag_graph_flags="--all -a --graph"
    local run_flags="--all -a --auth-provider-cmd --backend-bootstrap --backend-require-bootstrap --config --dependency-fetch-output-from-state --disable-bucket-update --disable-command-validation --download-dir --feature --graph --graph-root --iam-assume-role --iam-assume-role-duration --iam-assume-role-session-name --iam-assume-role-web-identity-token --inputs-debug --json-out-dir --no-auto-approve --no-auto-init --no-auto-retry --no-destroy-dependencies-check --no-stack-generate --out-dir --parallelism --provider-cache --provider-cache-dir --provider-cache-hostname --provider-cache-port --provider-cache-registry-names --provider-cache-token --queue-exclude-dir --queue-exclude-external --queue-excludes-file --queue-ignore-dag-order --queue-ignore-errors --queue-include-dir --queue-include-external --queue-include-units-reading --queue-strict-include --source --source-map --source-update --tf-forward-stdout --tf-path --units-that-include --use-partial-parse-config-cach"
    local hcl_fmt_flags="--all -a --check --diff --file --exclude-dir --stdin"
    local hcl_validate_flags="--all -a --graph --inputs --json --show-config-path --strict --inputs"
    local list_find_flags="--dag --dependencies --exclude --external --format --hidden --include --json -j --queue-construct-as --as"

    # Log levels for --log-level flag
    local log_levels="trace debug info warn error fatal panic stdout stderr"

    # First level: suggest main commands or global flags
    if [[ $cword -eq 1 ]] || _words_contains "$prev" "$global_flags"; then
        COMPREPLY=($(compgen -W "$commands $run_subcommands $global_flags" -- "$cur")); return
    fi

    # backend subcommands and flags
    if _words_contains "backend"; then
        if _words_contains "bootstrap"; then
            COMPREPLY=($(compgen -W "$backend_bootstrap_flags" -- "$cur")); return
        elif _words_contains "delete"; then
            COMPREPLY=($(compgen -W "$backend_delete_flags" -- "$cur")); return
        elif _words_contains "migrate"; then
            COMPREPLY=($(compgen -W "$backend_migrate_flags" -- "$cur")); return
        fi
        COMPREPLY=($(compgen -W "$bakend_subcommands" -- "$cur")); return
    fi

    # dag subcommands and flags
    if _words_contains "dag"; then
        if _words_contains "graph"; then
            COMPREPLY=($(compgen -W "$dag_graph_flags" -- "$cur")); return
        fi
        COMPREPLY=($(compgen -W "$dag_subcommands" -- "$cur")); return
    fi

    # find/list subcommands and flags
    if _words_contains "find" || _words_contains "list"; then
        if _words_contains "find|list"; then
            COMPREPLY=($(compgen -W "$list_find_flags" -- "$cur")); return
        fi
    fi

    # hcl subcommands and flags
    if _words_contains "hcl"; then
        if echo "${words[@]}"|grep -Eoq "format|fmt"; then
            COMPREPLY=($(compgen -W "$hcl_fmt_flags" -- "$cur")); return
        elif _words_contains "validate"; then
            COMPREPLY=($(compgen -W "$hcl_validate_flags" -- "$cur")); return
        fi
        COMPREPLY=($(compgen -W "$hcl_subcommands" -- "$cur")); return
    fi

    # run subcommands and flags
    if _words_contains "run"; then
        if [[ "$run_flags" == *"${prev}"* ]]; then
            COMPREPLY=($(compgen -W "$run_flags $run_subcommands" -- "$cur")); return
        else
            COMPREPLY=($(compgen -W "$run_flags" -- "$cur")); return
        fi
    fi

    # tf/tofu shortcut flags
    if _words_contains "apply"; then
        COMPREPLY=($(compgen -W "$apply_flags" -- "$cur")); return
    fi

    # Handle completion based on the first word (command)
    # case "${prev}" in
    #     backend)
    #         COMPREPLY=($(compgen -W "$bakend_subcommands" -- "$cur"))
    #         ;;
    #     run)
    #         # Suggest run subcommands or run-specific flags
    #         if [[ $cword -ge 3 && "$run_flags" == *"${prev}"* ]]; then
    #             COMPREPLY=($(compgen -W "$run_flags $run_subcommands" -- "$cur"))
    #         # Handle flags that take values
    #         elif [[ $cword -eq 3 && "${words[2]}" == "--log-level" ]]; then
    #             COMPREPLY=($(compgen -W "$log_levels" -- "$cur"))
    #         # Suggest files for --config or --working-dir
    #         elif [[ "${words[cword-1]}" == "--config" || "${words[cword-1]}" == "--working-dir" || "${words[cword-1]}" == "--cli-config-file" ]]; then
    #             COMPREPLY=($(compgen -f -- "$cur"))
    #         elif [[ $cword -eq 2 ]]; then
    #             COMPREPLY=($(compgen -W "$run_flags" -- "$cur"))
    #         fi
    #         ;;
    #     hcl)
    #         # Suggest hcl subcommands
    #         if [[ $cword -eq 2 ]]; then
    #             COMPREPLY=($(compgen -W "$hcl_subcommands" -- "$cur"))
    #         # Handle hcl fmt specific flags
    #         elif [[ $cword -ge 3 && "${words[2]}" == "fmt" ]]; then
    #             if [[ "${words[cword-1]}" == "--file" || "${words[cword-1]}" == "--exclude-dir" ]]; then
    #                 COMPREPLY=($(compgen -f -- "$cur"))
    #             else
    #                 COMPREPLY=($(compgen -W "$hcl_fmt_flags" -- "$cur"))
    #             fi
    #         fi
    #         ;;
    #     dag)
    #         # Suggest dag subcommands
    #         if [[ $cword -eq 2 ]]; then
    #             COMPREPLY=($(compgen -W "$dag_subcommands" -- "$cur"))
    #         fi
    #         ;;
    #     list|find)
    #         # Suggest list/find specific flags
    #         if [[ $cword -eq 2 ]]; then
    #             COMPREPLY=($(compgen -W "$list_find_flags" -- "$cur"))
    #         elif [[ "${words[cword-1]}" == "--format" ]]; then
    #             COMPREPLY=($(compgen -W "text json" -- "$cur"))
    #         elif [[ "${words[cword-1]}" == "--working-dir" ]]; then
    #             COMPREPLY=($(compgen -f -- "$cur"))
    #         else
    #             COMPREPLY=($(compgen -W "$list_find_flags" -- "$cur"))
    #         fi
    #         ;;
    #     *)
    #         # Suggest global flags for other commands or when no specific handling
    #         if [[ "${words[cword-1]}" == "--log-level" ]]; then
    #             COMPREPLY=($(compgen -W "$log_levels" -- "$cur"))
    #         elif [[ "apply" == "${prev}" ]]; then
    #             COMPREPLY=($(compgen -W "$apply_flags" -- "$cur"))
    #         elif [[ "${words[cword-1]}" == "--config" || "${words[cword-1]}" == "--working-dir" || "${words[cword-1]}" == "--cli-config-file" ]]; then
    #             COMPREPLY=($(compgen -f -- "$cur"))
    #         else
    #             COMPREPLY=($(compgen -W "$global_flags" -- "$cur"))
    #         fi
    #         ;;
    # esac

    # Handle colon-separated completions
    __ltrim_colon_completions "$cur"
}

# Register the completion function
alias tg='terragrunt'
complete -F _terragrunt_completion terragrunt
complete -F _terragrunt_completion tg
