#!/bin/bash

while read -r line
do
  echo "$line"
  if [[ $line =~ ^digraph\ \{$ ]]; then
    echo 'bgcolor = "#181818"; node [fontcolor = "#e6e6e6"; style = filled; color = "#e6e6e6"; fillcolor = "#333333";]; edge [color = "#e6e6e6"; fontcolor = "#e6e6e6";];'
  fi
done < "${1:-/dev/stdin}"
