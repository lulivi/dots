################################################################################
#                     T E R M I N A L   U T I L I T I E S                      #
################################################################################

# activate/a - activate venv
activate() {
    venv_name="${1:-.venv}"
    activate_script="${venv_name}/bin/activate"
    if [[ -f "$activate_script" ]]; then
        source "$activate_script"
    else
        printf '"%s" virtualenv does not exist.\n' "$venv_name" >&2
        return 127
    fi
}

telert() {
  RC="$?" $HOME/scripts/telegram_return_code.sh
}

# ex - archive extractor
# usage: ex <file>
ex() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar x $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# np - show current music
# usage: np
np() {
    if [ -n "$(playerctl metadata artist 2>/dev/null)" ]; then
        printf "$(playerctl metadata artist) - $(playerctl metadata title)\n"
    fi
}
