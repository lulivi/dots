################################################################################
#                     T E R M I N A L   U T I L I T I E S                      #
################################################################################

# activate - activate venv
# usage: activate <path/to/virtualenv>
activate() {
    _select_venv() {
        venv_listing=($@)
        if [ "1" -eq "${#venv_listing[@]}" ]; then
            printf "$venv_listing"
            return
        fi
        PS3="Choose virtual environment: "
        select option in ${venv_listing[@]}; do
            [ -n "$option" ] && {
                printf "$option"
                break
            }
        done
        unset PS3
    }
    venv_name="$1"

    shopt -s dotglob
    if [ -z "$venv_name" ]; then
       venv_name=$(_select_venv ./*venv*)
    fi
    shopt -u dotglob

    activate_script="${venv_name}/bin/activate"

    if [[ -f "$activate_script" ]]; then
        source "$activate_script"
    else
        printf '"%s" virtualenv does not exist.\n' "$venv_name" >&2
        return 127
    fi
}

# batf - bat as a tail replacement
# usage: batf <file>
batf() {
    file="$1"
    tail -f "$file" | bat --paging=never
}

todo() {
    ct ToDo
    vim ~/notes/todo.md
}

# mkcd - create dir and cd into it
# usage: mkcd <directory name>[/<subdirectory>[/..]]
mkcd() {
    _dirs="$1"
    mkdir -p $_dirs && pushd $_dirs
}

mksrc() {
    _pyver="${1:-3.7}"
    _venv="${2:-.venv}"
    python${_pyver} -m venv ${_venv} && source ${_venv}/bin/activate
}

# untar - extract tar file into a directory with the same name
# usage: untar <tar file>
untar() {
    _file="$1"
    _dir="${_file%.*}"
    mkdir -p $_dir
    tar -xvzf $_file -C $_dir
}

# autopatch - diff and patch file
# usage: autopatch <target> <source>
autopatch() {
    _target="$1"
    _source="$2"
    patch "$_target" <(diff -u "$_target" "$_source")
}

# mdrender - create a html preview of the markdown file
# usage: mdrender <markdown file>
mdrender() {
    _target="$(readlink -f "$1")"
    _output="/tmp/${_target##*/}.html"
    pandoc -f markdown -t html "${_target}" > "${_output}"
    printf 'Rendered file: %s\n' "$_output"
}

# mdrenderopen - open html preview of the markdown file
# usage: mdrenderopen <markdown file>
mdrenderopen() {
    _output=($(mdrender $@))
    open "${_output[2]}"
}

docker_run() {
    _image="${1}"
    [ -z "$_image" ] && {
        printf 'Please, provide the image id\n' >&2
        return
    }
    docker run --rm -it ${_image} /bin/bash
}
