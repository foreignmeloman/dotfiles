function retmux {
  top_session="$(tmux ls -F '#{session_name}'|head -1)"
  tmux a -t "${1:-${top_session}}"
}

function _complete_retmux {
  local cur prev options
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  options=("$(tmux ls -F '#{session_name}')")
  if [[ "${options[*]}" == *"$prev"* ]]; then
    COMPREPLY=(); return
  fi
  COMPREPLY=($(compgen -W "${options[@]}" -- "$cur"))
}

alias rtx='retmux'
complete -F _complete_retmux retmux
complete -F _complete_retmux rtx
