# Add item to a path-like variable
# Usage: source add_paths_to_variable <path_var_name> <path_1> [<path_2> [...]]
_call() {
  local path_variable_name="$1"
  shift 1
  local new_paths=("$@")

  for new_path in ${new_paths[@]}; do
    if [[ ${!path_variable_name} != *$new_path* ]]; then
      export $path_variable_name="$new_path":${!path_variable_name}
    else
      printf '[WARNING] "%s" path already in $%s.\n' \
        "$new_path" \
        "$path_variable_name"
    fi
  done
}

_call $@; unset -f _call
