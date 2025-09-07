if command -v tfenv > /dev/null; then
  function __complete_tfenv {
    local CMD=$1 COMP=$2 PREV_CMD=$3
    local -a SUPPORTED_CMDS
    COMPREPLY=()
    case $PREV_CMD in
      $CMD)
        SUPPORTED_CMDS=($(tfenv -h | sed -En '/^Commands/,$ {s/ +([-a-z]+) +.+/\1/p}'))
        compopt -o nosort
        COMPREPLY=($(compgen -W "${SUPPORTED_CMDS[*]}" -- "$COMP"))
        return 0
        ;;
      install)
        COMPREPLY=($(compgen -W "$(tfenv list-remote | grep -Po '\d+(\.\d+){2,}(-\w+)?')" -- "$COMP"))
        return 0
        ;;
      use|uninstall)
        COMPREPLY=($(compgen -W "$(tfenv list | grep -Po '\d+(\.\d+){2,}(-\w+)?')" -- "$COMP"))
        return 0
        ;;
      init|list*|version-name|pin)
        return 0
        ;;
      *)
        return 0
        ;;
    esac
  }
  complete -F __complete_tfenv tfenv
fi
