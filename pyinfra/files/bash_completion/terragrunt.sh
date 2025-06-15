_terragrunt_completion() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    function _words_contains {
        local list="${2:-${words[@]}}"
        echo "$list"|grep -Eoq "(^| )$1"
    }

    # Main Terragrunt commands
    local commands="backend exec run stack catalog scaffold find fd list ls dag hcl info render"
    local backend_subcommands="bootstrap delete migrate"
    local run_subcommands="plan apply destroy init validate import output state show refresh taint untaint force-unlock"
    local hcl_subcommands="format fmt validate"
    local dag_subcommands="graph"

    # Global flags
    local global_flags="--experiment --experiment-mode --log-custom-format --log-disable --log-format --log-level --log-show-abs-paths --no-color --non-interactive --strict-control --strict-mode --working-dir --help -h --version -v"

    # Command-specific flags
    local apply_flags="-auto-approve -backup -compact-warnings -destroy -lock -lock-timeout -input= -no-color -parallelism -state -state-out -target -var -var-file"
    local backend_bootstrap_flags="--all -a --config --download-dir"
    local backend_delete_flags="--all -a --config --download-dir --force"
    local backend_migrate_flags="--config --download-dir --force"
    local dag_graph_flags="--all -a --graph"
    local hcl_fmt_flags="--all -a --check --diff --file --exclude-dir --stdin"
    local hcl_validate_flags="--all -a --graph --inputs --json --show-config-path --strict --inputs"
    local init_flags="-backend -backend-config -force-copy -from-module -get -input -lock -lock-timeout -no-color -json -plugin-dir -reconfigure -migrate-state -upgrade -lockfile -ignore-remote-version -test-directory"
    local list_find_flags="--dag --dependencies --exclude --external --format --hidden --include --json -j --queue-construct-as --as"
    local plan_flags="-destroy -refresh-only -refresh -replace -target -var -var-file -compact-warnings -detailed-exitcode -generate-config-out -input -lock -lock-timeout -no-color -out -parallelism -state"
    local run_flags="--all -a --auth-provider-cmd --backend-bootstrap --backend-require-bootstrap --config --dependency-fetch-output-from-state --disable-bucket-update --disable-command-validation --download-dir --feature --graph --graph-root --iam-assume-role --iam-assume-role-duration --iam-assume-role-session-name --iam-assume-role-web-identity-token --inputs-debug --json-out-dir --no-auto-approve --no-auto-init --no-auto-retry --no-destroy-dependencies-check --no-stack-generate --out-dir --parallelism --provider-cache --provider-cache-dir --provider-cache-hostname --provider-cache-port --provider-cache-registry-names --provider-cache-token --queue-exclude-dir --queue-exclude-external --queue-excludes-file --queue-ignore-dag-order --queue-ignore-errors --queue-include-dir --queue-include-external --queue-include-units-reading --queue-strict-include --source --source-map --source-update --tf-forward-stdout --tf-path --units-that-include --use-partial-parse-config-cach"

    # Log levels for --log-level flag
    local log_levels="trace debug info warn error fatal panic stdout stderr"

    # Suggest file paths for certain flags
    if [[ "${prev}" =~ -?-([a-z]+-)*(config|file|out)$ ]]; then
        compopt -o nospace
        COMPREPLY=()
        for item in $(compgen -f -- "$cur"); do
            [[ -d "$item" ]] && COMPREPLY+=("$item/") || COMPREPLY+=("$item")
        done
        return
    fi

    # Suggest directory paths for flags that expect directories as arguments
    if [[ "${prev}" =~ -?-([a-z]+-)+dir(ectory)?$ ]]; then
        compopt -o nospace
        COMPREPLY=($(compgen -d -S "/" -- "$cur")); return
    fi

    # Suggest log levels for --log-level
    if [[ "$prev" == "--log-level" ]]; then
        COMPREPLY=($(compgen -W "$log_levels" -- "$cur")); return
    fi

    # First level: suggest main commands or global flags. TODO FIX THIS
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
        COMPREPLY=($(compgen -W "$backend_subcommands" -- "$cur")); return
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
        COMPREPLY=($(compgen -W "$list_find_flags" -- "$cur")); return
    fi

    # hcl subcommands and flags
    if _words_contains "hcl"; then
        if _words_contains "format|fmt"; then
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
    elif _words_contains "init"; then
        COMPREPLY=($(compgen -W "$init_flags" -- "$cur")); return
    elif _words_contains "plan"; then
        COMPREPLY=($(compgen -W "$plan_flags" -- "$cur")); return
    fi

    # Handle colon-separated completions
    __ltrim_colon_completions "$cur"
}

# Register the completion function
alias tg='terragrunt'
complete -F _terragrunt_completion terragrunt
complete -F _terragrunt_completion tg
