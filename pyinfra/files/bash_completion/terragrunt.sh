function _tg_cmd_options {
  # Example args: terragrunt dag graph ...
  while IFS= read -r line; do
    if [[ "${line}" =~ ^([A-Z][a-z]+ c|C)ommands:$ ]] || [[ "${line}" =~ ^(Global\ )?Options:$ ]]; then
      found_tg_commands=1
      continue
    fi

    if [[ -n $found_tg_commands ]] && [[ "${line}" =~ ^\ +([a-z][a-z\-]+|--[a-z\-]+)(, (-[a-z]|[a-z][a-z\-]+))? ]]; then
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
  done < <("$1" -help)
}

function _terragrunt_completion {
  compopt -o nosort
  local cmd cur prev opts
  cmd="${COMP_WORDS[0]}"
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Log levels for --log-level flag
  local log_levels="trace debug info warn error fatal panic stdout stderr"

  # local tf_shortcuts="$(_tg_tf_shortcuts "$cmd"|tr '\n' '|')"

  # Suggest file paths for certain flags
  if [[ "$prev" =~ -?-([a-z]+-)*(config|file|out)$ || "-backup -state" == *"$prev"* ]]; then
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

  # echo "COMP_CWORD=$COMP_CWORD|COMP_LINE=$COMP_LINE|COMP_POINT=$COMP_POINT|COMP_WORDS=${COMP_WORDS[*]}|" >> tg.log

  # Strip unfinished flags from the request
  if [[ $cur =~ -?-[a-z\-]+ ]]; then
    opts="$(_tg_cmd_options "${COMP_WORDS[@]:0:${#COMP_WORDS[@]}-1}")" 
  else
    opts="$(_tg_cmd_options "${COMP_WORDS[@]}")"
  fi
  COMPREPLY+=($(compgen -W "$opts" -- "$cur")); return
}

# Register the completion function
function tg { terragrunt "$@"; }
complete -F _terragrunt_completion terragrunt
complete -F _terragrunt_completion tg
