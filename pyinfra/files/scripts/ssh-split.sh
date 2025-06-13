#!/bin/bash

if [ "${TERM_PROGRAM}" != 'tmux' ]; then
  echo 'Error: Must be run inside a tmux session!'
  exit 1
fi

ssh_list=($@)

split_list=()
for ssh_entry in "${ssh_list[@]:1}"; do
  split_list+=( split-pane ssh "${ssh_entry}" ';' select-layout tiled ';' )
done

base_index=$(tmux display -p '#{pane-base-index}')

tmux new-window ssh "${ssh_list[0]}" ';' \
  "${split_list[@]}" \
  rename-window "$(basename $0)" ';' \
  select-pane -t "${base_index}" ';' \
  set-option -w synchronize-panes
