function _tg_cmd_options {
  # Example args: terragrunt dag graph ...
  while IFS= read -r line; do
    if [[ "${line}" =~ ^([A-Z][a-z]+ c|C)ommands:$ ]]; then
      found_tg_commands=1
      continue
    fi

    if [[ -n $found_tg_commands ]] && [[ "${line}" =~ ^\ +([a-z][a-z\-]+|--[a-z\-]+)(, (-[a-z]))? ]]; then
      echo -e "${BASH_REMATCH[1]}"
      if [[ -n "${BASH_REMATCH[3]}" ]]; then
        echo -e "${BASH_REMATCH[3]}"
      fi
    fi
  done < <("$@" --help)
}

function _tg_tf_shortcuts {
  # Example args: terragrunt
  while IFS= read -r line; do
    if [[ "${line}" =~ ^OpenTofu\ shortcuts:$ ]]; then
      found_tofu_shortcuts=1
      continue
    fi

    if [[ -n $found_tofu_shortcuts ]] && [[ "${line}" =~ ^\ +([a-z][a-z\-]+) ]]; then
      echo -e "${BASH_REMATCH[1]}"
    fi
  done < <("$1" --help)
}

function _terragrunt_completion {
  local cur prev words cword
  _get_comp_words_by_ref -n : cur prev words cword

  # Main Terragrunt commands
  local commands="backend exec run stack catalog scaffold find fd list ls dag hcl info render"
  local backend_subcommands="bootstrap delete migrate"
  local run_subcommands="plan apply destroy init validate import output state show refresh taint untaint force-unlock"
  local hcl_subcommands="format fmt validate"
  local dag_subcommands="graph"

  function cmd_stack {
      local all_commands="${commands} ${backend_subcommands} ${run_subcommands} ${hcl_subcommands} ${dag_subcommands}"
      echo "${words[*]}"|grep -Eo "(^| )${all_commands// /|}"|tr '\n' ' '
  }

  # Global flags
  local global_flags="--experiment --experiment-mode --log-custom-format --log-disable --log-format --log-level --log-show-abs-paths --no-color --non-interactive --strict-control --strict-mode --tf-path --working-dir --help -h --version -v"

  # Command-specific flags
  local apply_flags="-auto-approve -backup -compact-warnings -destroy -lock -lock-timeout -input -no-color -parallelism -state -state-out -target -var -var-file"
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

  # Suggest global flags by default
  COMPREPLY=($(compgen -W "$global_flags" -- "$cur"))

  # Suggest file paths for certain flags
  if [[ "${prev}" =~ -?-([a-z]+-)*(config|file|out)$ || "-backup -state" == *"$prev"* ]]; then
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

  # echo depth="$(cmd_stack | wc -w)" cmds="$(cmd_stack) | $cur | $prev | ${words[*]} | $cword" >> tg.log

  cmd_stack_array=($(cmd_stack))
  case ${cmd_stack_array[0]} in
    # main commands
    backend)
      case ${cmd_stack_array[1]} in
        bootstrap)
          COMPREPLY+=($(compgen -W "$backend_bootstrap_flags" -- "$cur")); return
          ;;
        delete)
          COMPREPLY+=($(compgen -W "$backend_delete_flags" -- "$cur")); return
          ;;
        migrate)
          COMPREPLY+=($(compgen -W "$backend_migrate_flags" -- "$cur")); return
          ;;
        "")
          COMPREPLY+=($(compgen -W "$backend_subcommands" -- "$cur")); return
          ;;
      esac
      ;;
    dag)
      case ${cmd_stack_array[1]} in
        graph)
          COMPREPLY+=($(compgen -W "$dag_graph_flags" -- "$cur")); return
          ;;
        "")
          COMPREPLY+=($(compgen -W "$dag_subcommands" -- "$cur")); return
          ;;
      esac
      ;;
    find|list)
      COMPREPLY+=($(compgen -W "$list_find_flags" -- "$cur")); return
      ;;
    hcl)
      case ${cmd_stack_array[1]} in
        format|fmt)
          COMPREPLY+=($(compgen -W "$hcl_fmt_flags" -- "$cur")); return
          ;;
        validate)
          COMPREPLY+=($(compgen -W "$hcl_validate_flags" -- "$cur")); return
          ;;
        "")
          COMPREPLY+=($(compgen -W "$hcl_subcommands" -- "$cur")); return
          ;;
      esac
      ;;
    run)
        if [[ -z ${cmd_stack_array[1]} ]]; then
          COMPREPLY+=($(compgen -W "$run_flags $run_subcommands" -- "$cur")); return
        fi
        COMPREPLY+=($(compgen -W "$run_flags" -- "$cur")); return
        ;;

    # tf/tofu shortcut flags
    apply)
      COMPREPLY+=($(compgen -W "$apply_flags" -- "$cur")); return
      ;;
    init)
      COMPREPLY+=($(compgen -W "$init_flags" -- "$cur")); return
      ;;
    plan)
      COMPREPLY+=($(compgen -W "$plan_flags" -- "$cur")); return
      ;;
    "")
      COMPREPLY+=($(compgen -W "$commands $run_subcommands" -- "$cur")); return
      ;;
  esac
}

# Register the completion function
alias tg='terragrunt'
complete -F _terragrunt_completion terragrunt
complete -F _terragrunt_completion tg
