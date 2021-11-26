# Remove an item from a path-like variable
# Usage: source del_paths_from_variable <path_var_name> <path_1> [<path_2> [...]]
_call() {
    local path_variable_name="$1"
    local path_variable_contents="${!path_variable_name}"
    shift 1
    local del_paths=("$@")
    local path_to_remove=""

    for del_path in ${del_paths[@]}; do
        scaped_del_path="${del_path//\//\\\/}"
        cleaned_del_path="${scaped_del_path//\./\\\.}"
        case "${!path_variable_name}" in
            (${cleaned_del_path}:*)
                path_to_remove="${cleaned_del_path}:"
                ;;
            (*:${cleaned_del_path}*)
                path_to_remove=":${cleaned_del_path}"
                ;;
            (*)
                printf '[WARNING] "%s" is not in "$%s"\n' \
                    "$del_path" \
                    "$path_variable_name"
                path_to_remove=""
                ;;
        esac
        path_variable_contents="${path_variable_contents/${path_to_remove}}"
    done
    export $path_variable_name="$path_variable_contents"
}

_call $@; unset -f _call
