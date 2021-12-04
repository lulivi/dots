# Source shell scripts
# Usage: source load_shell_scripts [<path_to_script> | <path_to_dir>]
_call() {
  local script_path="$1"

  if [ -d "$script_path" ]; then
    for subscript_path in $script_path/*.sh; do
      if [ -r "$subscript_path" ]; then
        . "$subscript_path"
      else
        printf '[WARNING] "%s" does not exists or is not a shell script.\n' \
          "$subscript_path"
      fi
    done
  elif [ -r "$script_path" ]; then
    . "$script_path"
  else
    printf '[WARNING] "%s" does not exists or is not a shell script.\n' \
      "$script_path"
  fi
}

_call $@; unset -f _call
