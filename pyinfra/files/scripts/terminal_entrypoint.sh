#!/bin/bash

if [[ -z "${TMUX}" ]]; then
  if tmux has-session -t "main" 2> /dev/null; then
    tmux a -t main
  else
    cd || exit
    tmux new -s main
  fi
fi
