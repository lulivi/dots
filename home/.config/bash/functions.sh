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

# send_telegram_message - send a telegram message to CHAT_ID with a bot
# ussage: send_telegram_message "<message_to_send>"
send_telegram_message() {
    message="$1"

    if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        printf 'Please be sure that $BOT_TOKEN and $CHAT_ID are set.\n'
        return 1
    fi

    if [ -z "$message" ]; then
        printf 'There is no message to send. Aborting.'
        return 1
    elif [ "${#message}" -gt "4096" ]; then
        printf -v message '%s\n```... The message has been trimmed.' \
            "${message:0:4066}"
    fi

    URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
    DATA="chat_id=${CHAT_ID}&parse_mode=Markdown&text=${message}"

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

send_telegram_document() {
    document="$(realpath -P $1)"
    caption="$2"

    if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        printf 'Please be sure that $BOT_TOKEN and $CHAT_ID are set.\n'
        return 1
    fi

    if ! [ -f "$document" ]; then
        printf 'There is no document to send. Aborting.\n'
        return 1
    else
        printf 'Sending document "%s"...\n' "$document"
    fi

    URL="https://api.telegram.org/bot${BOT_TOKEN}/sendDocument"
    DATA=(
        "-F \"chat_id=${CHAT_ID}\""
        "-F \"parse_mode=Markdown\""
        "-F \"document=@${document};${document##*/}\""
    )
    request="curl -s -k ${DATA[@]} $URL"
    printf 'Request:\n\t%s\n' "$request"

    obtained_json="$($request)"
    petition_ok="$(printf '%s' "$obtained_json" | jq .ok)"

    if [ "$petition_ok" == "false" ]; then
        printf 'There was an error: '
        printf '%s' "$obtained_json" | jq
        printf '\nPetition parementers:\n%s\n' "$DATA"
        return 1
    fi

    return 0
}

# telpipe - send notification with previous command output
# usage: <comand> | telpipe
telpipe() {
    header='\n--------------------- Output ---------------------'
    printf -v previous_output '```\n%b%s\n```' "$header" "$(< /dev/stdin)"
    send_telegram_message "$previous_output"
}

# telret - send notification with previous command return code
# usage: <comand>; telret
telret() {
    printf -v message '💽=`%s`' "$?"
    notify-send "Sending notification" "$message"
    send_telegram_message "$message"
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

# batf - bat as a tail replacement
# usage: batf <file>
batf() {
    file="$1"
    tail -f "$file" | bat --paging=never
}

# ct - change terminal window title
# usage: ct "<text>"
ct() {
    echo -n -e "\033]0;${1}\007"
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
