_terragrunt_completion() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    # Main Terragrunt commands
    local commands="run exec hcl dag info render list find apply destroy force-unlock import init output plan refresh show state test validate"
    local run_subcommands="plan apply destroy init validate import output state show refresh taint untaint force-unlock"
    local hcl_subcommands="fmt validate"
    local dag_subcommands="graph"

    # Global flags
    local global_flags="--experiment --experiment-mode --log-custom-format --log-disable --log-format --log-level --log-show-abs-paths --no-color --non-interactive --strict-control --strict-mode --working-dir --help, -h --version -v"

    # Command-specific flags
    local run_flags=" --all -a --auth-provider-cmd --backend-bootstrap --backend-require-bootstrap --config --dependency-fetch-output-from-state --disable-bucket-update --disable-command-validation --download-dir --feature --graph --graph-root --iam-assume-role --iam-assume-role-duration --iam-assume-role-session-name --iam-assume-role-web-identity-token --inputs-debug --json-out-dir --no-auto-approve --no-auto-init --no-auto-retry --no-destroy-dependencies-check --no-stack-generate --out-dir --parallelism --provider-cache --provider-cache-dir --provider-cache-hostname --provider-cache-port --provider-cache-registry-names --provider-cache-token --queue-exclude-dir --queue-exclude-external --queue-excludes-file --queue-ignore-dag-order --queue-ignore-errors --queue-include-dir --queue-include-external --queue-include-units-reading --queue-strict-include --source --source-map --source-update --tf-forward-stdout --tf-path --units-that-include --use-partial-parse-config-cach"
    local hcl_fmt_flags="-a --all --check --diff --file --exclude-dir --stdin"
    local list_find_flags="--dag --dependencies --exclude --external --format --hidden --include --json -j --queue-construct-as --as"

    # Log levels for --log-level flag
    local log_levels="trace debug info warn error fatal panic stdout stderr"

    # First level: suggest main commands or global flags
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands $global_flags" -- "$cur"))
        return
    fi

    # Handle completion based on the first word (command)
    case "${words[1]}" in
        run)
            # Suggest run subcommands or run-specific flags
            if [[ $cword -ge 3 && "$run_flags" == *"${prev}"* ]]; then
                COMPREPLY=($(compgen -W "$run_flags $run_subcommands" -- "$cur"))
            # Handle flags that take values
            elif [[ $cword -eq 3 && "${words[2]}" == "--log-level" ]]; then
                COMPREPLY=($(compgen -W "$log_levels" -- "$cur"))
            # Suggest files for --config or --working-dir
            elif [[ "${words[cword-1]}" == "--config" || "${words[cword-1]}" == "--working-dir" || "${words[cword-1]}" == "--cli-config-file" ]]; then
                COMPREPLY=($(compgen -f -- "$cur"))
            elif [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$run_flags" -- "$cur"))
            fi
            ;;
        hcl)
            # Suggest hcl subcommands
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$hcl_subcommands" -- "$cur"))
            # Handle hcl fmt specific flags
            elif [[ $cword -ge 3 && "${words[2]}" == "fmt" ]]; then
                if [[ "${words[cword-1]}" == "--file" || "${words[cword-1]}" == "--exclude-dir" ]]; then
                    COMPREPLY=($(compgen -f -- "$cur"))
                else
                    COMPREPLY=($(compgen -W "$hcl_fmt_flags" -- "$cur"))
                fi
            fi
            ;;
        dag)
            # Suggest dag subcommands
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$dag_subcommands" -- "$cur"))
            fi
            ;;
        list|find)
            # Suggest list/find specific flags
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$list_find_flags" -- "$cur"))
            elif [[ "${words[cword-1]}" == "--format" ]]; then
                COMPREPLY=($(compgen -W "text json" -- "$cur"))
            elif [[ "${words[cword-1]}" == "--working-dir" ]]; then
                COMPREPLY=($(compgen -f -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$list_find_flags" -- "$cur"))
            fi
            ;;
        *)
            # Suggest global flags for other commands or when no specific handling
            if [[ "${words[cword-1]}" == "--log-level" ]]; then
                COMPREPLY=($(compgen -W "$log_levels" -- "$cur"))
            elif [[ "${words[cword-1]}" == "--config" || "${words[cword-1]}" == "--working-dir" || "${words[cword-1]}" == "--cli-config-file" ]]; then
                COMPREPLY=($(compgen -f -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$global_flags" -- "$cur"))
            fi
            ;;
    esac

    # Handle colon-separated completions
    __ltrim_colon_completions "$cur"
}

# Register the completion function
alias tg='terragrunt'
complete -F _terragrunt_completion terragrunt
complete -F _terragrunt_completion tg
