function _tf_cmd_options {
  local found_tf_commands=0
  local found_tf_flags=0
  while IFS= read -r line; do
    if [[ "${line}" =~ ^((Main|All other) |Sub)commands:$ ]]; then
      found_tf_commands=1
      continue
    fi

    if [[ $found_tf_commands -eq 1 ]] && [[ "${line}" =~ ^\ {2,4}([a-z][a-z\-]+) ]]; then
      echo -e "${BASH_REMATCH[1]}"
    fi

    if [[ "${line}" =~ ^(Global options.+|(Plan Customization )?Options):$ ]]; then
      found_tf_commands=0
      found_tf_flags=1
      continue
    fi

    if [[ $found_tf_flags -eq 1 ]] && [[ "${line}" =~ ^\ {2,4}(-[a-z\-]+) ]]; then
      echo -e "${BASH_REMATCH[1]}"
    fi

  done < <("$@" -help 2> /dev/null)
}

function _tg_cmd_options {
  # Example args: terragrunt dag graph ...
  local found_tg_commands=0
  while IFS= read -r line; do
    if [[ "${line}" =~ ^([A-Z][a-z]+ c|C)ommands:$ ]] || [[ "${line}" =~ ^(Global )?Options:$ ]]; then
      found_tg_commands=1
      continue
    fi
    # shellcheck disable=SC2016
    local tf_pattern='^ +This is a shortcut for the command `terragrunt run`\.$'
    if [[ "${line}" =~ $tf_pattern ]]; then
      local terraform_binary
      terraform_binary=$($1 info print|awk -F': *' '/"terraform_binary"/ { gsub(/[",]/, "", $2); print $2 }')
      _tf_cmd_options "$terraform_binary" "${@:2:$#}"
      break
    fi
    if [[ $found_tg_commands -eq 1 ]] && [[ "${line}" =~ ^\ +([a-z][a-z\-]+|--[a-z\-]+)(, (-[a-z]|[a-z][a-z\-]+))? ]]; then
      echo -e "${BASH_REMATCH[1]}"
      if [[ -n "${BASH_REMATCH[3]}" ]]; then
        echo -e "${BASH_REMATCH[3]}"
      fi
    fi
  done < <("$@" --help 2> /dev/null)
}

function _terragrunt_completion {
  compopt -o nosort
  local cur prev opts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Log levels for --log-level flag
  local log_levels="trace debug info warn error fatal panic stdout stderr"

  # Suggest file paths for certain flags
  if [[ "$prev" =~ -?-([a-z]+-)*(config|file|out)$ || "$prev" =~ -backup|-state ]]; then
    compopt -o nospace
    COMPREPLY=()
    for item in $(compgen -f -- "$cur"); do
      [[ -d "$item" ]] && COMPREPLY+=("$item/") || COMPREPLY+=("$item")
    done
    return
  fi

  # Suggest directory paths for flags that expect directories as arguments
  if [[ "$prev" =~ -?-([a-z]+-)+dir(ectory)?$ ]]; then
    compopt -o nospace
    COMPREPLY=($(compgen -d -S "/" -- "$cur")); return
  fi

  # Suggest log levels for --log-level
  if [[ "$prev" == "--log-level" ]]; then
    COMPREPLY=($(compgen -W "$log_levels" -- "$cur")); return
  fi

  if (( $COMP_POINT < ${#COMP_LINE} )); then
    local cursor_args
    read -ra cursor_args <<< "${COMP_LINE:0:${COMP_POINT}}"
    opts="$(_tg_cmd_options "${cursor_args[@]}")"
    cur="${cursor_args[-1]}"
    if [[ $cur =~ -?-[a-z\-]+ ]]; then
       opts="$(_tg_cmd_options "${cursor_args[@]:0:${#cursor_args[@]}-1}")"
    fi
  # Strip last flag from the request as it may be unfinished and confuse _tg_cmd_options logic
  # Or strip the last command if it's not followed by space for the right options to be generated
  elif [[ $cur =~ -?-[a-z\-]+ ]] || [[ ! $COMP_LINE =~ [[:space:]]$ ]]; then
    opts="$(_tg_cmd_options "${COMP_WORDS[@]:0:${#COMP_WORDS[@]}-1}")"
  else
    opts="$(_tg_cmd_options "${COMP_WORDS[@]}")"
  fi
  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

# Register the completion function
function tg { terragrunt "$@"; }
complete -F _terragrunt_completion terragrunt
complete -F _terragrunt_completion tg
