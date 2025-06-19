function _tg_cmd_options {
  # Example args: terragrunt dag graph ...
  # echo "_tg_cmd_options $@">> tg.log
  # echo >> tg.log
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
  done < <("$@" --help 2> /dev/null)
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

  # echo "-------------start------------" >> tg.log
  # echo "COMP_CWORD=$COMP_CWORD|COMP_LINE=$COMP_LINE|COMP_POINT=$COMP_POINT|COMP_WORDS=${COMP_WORDS[*]}|cur=$cur|" >> tg.log
  # echo >> tg.log

  if (( $COMP_POINT < ${#COMP_LINE} )); then
    local args
    read -a args <<< "${COMP_LINE:0:${COMP_POINT}}"
    opts="$(_tg_cmd_options "${args[@]}")"
    # echo "args=${args[@]}" >> tg.log
    # echo >> tg.log
    cur="${args[-1]}"
    if [[ $cur =~ -?-[a-z\-]+ ]]; then
       opts="$(_tg_cmd_options "${args[@]:0:${#args[@]}-1}")"
    fi
  # Strip last flag from the request as it may be unfinished and confuse _tg_cmd_options logic
  # Or strip the last command if it's not followed by space for the right options to be generated
  elif [[ $cur =~ -?-[a-z\-]+ ]] || [[ ! $COMP_LINE =~ [[:space:]]$ ]]; then
    opts="$(_tg_cmd_options "${COMP_WORDS[@]:0:${#COMP_WORDS[@]}-1}")" 
  else
    opts="$(_tg_cmd_options "${COMP_WORDS[@]}")"
  fi
  # echo "COMPREPLY=$(compgen -W "$opts" -- "$cur"|xargs)" >> tg.log
  # echo >> tg.log
  # echo "opts=$opts"|xargs >> tg.log
  # echo "-------------end------------" >> tg.log
  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

# Register the completion function
function tg { terragrunt "$@"; }
complete -F _terragrunt_completion terragrunt
complete -F _terragrunt_completion tg
