################################################################################
#                     T E R M I N A L   U T I L I T I E S                      #
################################################################################

# activate - activate venv
# usage: activate <path/to/virtualenv>
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

# telert - send notification with previous command return code
# usage: <comand>; telert
telert() {
    RC="$?"

    if [ -z "$BOT_TOKEN" OR -z "$CHAT_ID" ]; then
        printf 'Please be sure that $BOT_TOKEN and $CHAT_ID are set.\n'
        return 1
    fi

    TEXT="$(printf 'Process finished\nReturn code = `%s`' "${RC}")"
    URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
    DATA="chat_id=${CHAT_ID}&parse_mode=Markdown&text=${TEXT}"

    obtained_json="$(curl -s --data "$DATA" $URL)"
    petition_ok="$(printf '%s' "$obtained_json" | jq .ok)"

    if [ "$petition_ok" == "false" ]; then
        printf 'There was an error: '
        printf '%s' "$obtained_json" | jq
        printf '\nPetition parementers:\n%s\n' "$DATA"
        return 1
    fi

    return 0
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
        printf '%s - %s\n' \
            "$(playerctl metadata artist)" \
            "$(playerctl metadata title)"
    else
        printf 'No players found.\n'
    fi
}

