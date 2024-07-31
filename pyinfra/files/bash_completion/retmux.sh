function retmux {
  if [[ ${1} == '' ]]; then
    tmux a -t $(tmux ls|head -1|awk -F':' '{print $1}')
  else
    tmux a -t ${1}
  fi
}

function _complete_retmux {
  tmux_sessions=$(tmux ls 2> /dev/null|awk -F':' '{print $1}')
  options=()
  if [[ ${1} == ${3} ]]; then
    options=(${tmux_sessions[@]})
  fi
  COMPREPLY=($(compgen -W "${options[*]}" "${COMP_WORDS[${COMP_CWORD}]}"))
}

complete -o nospace -F _complete_retmux retmux
