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

function _terraform_completion {
  compopt -o nosort
  local cur prev opts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

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

  if (( $COMP_POINT < ${#COMP_LINE} )); then
    local cursor_args
    read -ra cursor_args <<< "${COMP_LINE:0:${COMP_POINT}}"
    opts="$(_tf_cmd_options "${cursor_args[@]}")"
    cur="${cursor_args[-1]}"
    if [[ $cur =~ -?-[a-z\-]+ ]]; then
       opts="$(_tf_cmd_options "${cursor_args[@]:0:${#cursor_args[@]}-1}")"
    fi
  # Strip last flag from the request as it may be unfinished and confuse _tf_cmd_options logic
  # Or strip the last command if it's not followed by space for the right options to be generated
  elif [[ $cur =~ -?-[a-z\-]+ ]] || [[ ! $COMP_LINE =~ [[:space:]]$ ]]; then
    opts="$(_tf_cmd_options "${COMP_WORDS[@]:0:${#COMP_WORDS[@]}-1}")"
  else
    opts="$(_tf_cmd_options "${COMP_WORDS[@]}")"
  fi
  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

# Register the completion function
if command -v terraform > /dev/null; then
  complete -F _terraform_completion terraform
  complete -F _terraform_completion tf
fi
