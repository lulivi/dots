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
    local venv_name="$1"

    if [ -f "./pyproject.toml" ]; then
        poetry shell
        return
    fi

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

# mkcd - create dir and cd into it
# usage: mkcd <directory name>[/<subdirectory>[/..]]
mkcd() {
    local _dirs="$1"
    mkdir -p $_dirs && pushd $_dirs
}

# mksrc - create a Python virtual environment and source it
# usage: mksrc [<python version> [<venv name>]]
mksrc() {
    local _pyver="${1:-3.7}"
    local _venv="${2:-.venv}"
    python${_pyver} -m venv ${_venv} && source ${_venv}/bin/activate
}
