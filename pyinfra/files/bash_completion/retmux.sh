function retmux {
  if [[ $1 == '' ]]; then
    tmux a -t "$(tmux ls -F '#{session_name}'|head -1)"
  else
    tmux a -t "$1"
  fi
}

function _complete_retmux {
  local cur prev words cword options
  _get_comp_words_by_ref -n : cur prev words cword
  options=("$(tmux ls -F '#{session_name}')")
  if [[ "${options[*]}" == *"$prev"* ]]; then
    COMPREPLY=(); return
  fi
  COMPREPLY=($(compgen -W "${options[@]}" -- "$cur"))
}

alias rtx='retmux'
complete -F _complete_retmux retmux
complete -F _complete_retmux rtx
