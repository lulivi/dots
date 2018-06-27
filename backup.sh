#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán
#==============================================================================
##
## Usage: ${SCRIPT_NAME} [OPTIONS]
##
## Options:
##   -h                   Display this message.
##   -f <file_list_json>  Select file list in a json-like file.
##                        Default: file_list.json
##   -u                   Only show updated files
##   -r                   Restore local files from the repository
##

SCRIPT_NAME="$(basename ${0})"
SCRIPT_PATH="$(dirname ${0})"

usage() {
    [[ -n "$1" ]] && printf '\n%s\n' "$1"
    grep -e "^##" $SCRIPT_PATH/$SCRIPT_NAME | \
        sed -e "s/^## \{0,1\}//g" \
            -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"
    exit 2
} 2>/dev/null

exit_error () {
    echo "ERROR: $1"
    usage
    exit 1
}

while getopts "hf:ru" args; do
    case "${args}" in
        (h) # Display help
            usage 2>&1;;
        (f) # Specified file liest
            file_list="${OPTARG}";;
        (r) # Inverse backup
            RESTORE=true;;
        (u)
            ONLY_UPDATES=true;;
        (--)
            shift; break;;
        (-*)
            usage "$1: unknown option";;
        (*)
            break;;
    esac
done
shift $((OPTIND-1))

# The current script execution purpose
declare SCRIPT_PURPOSE
# The destination folder (only for restore purposes)
declare TARGET_DIR
# The origin folder
declare SOURCE_DIR

# Asign SOURCE_DIR and RESTORE_DIR
[ $RESTORE ] && {
    SCRIPT_PURPOSE="restore"
    SOURCE_DIR="$(realpath $(dirname $0))"
    TARGET_DIR="$HOME"
} || {
    SCRIPT_PURPOSE="backup"
    SOURCE_DIR="$HOME"
    TARGET_DIR="$(realpath $(dirname $0))"
}

# Check if the file list json is given
[[ -n $file_list && -f $file_list ]] || {
    [ -f ./file_list.json ] && {
        file_list=$SCRIPT_PATH/file_list.json
    } || {
        exit_error "There is not a list of files to $SCRIPT_FUNCTION. Please, \
indicate it with the -f opttion"
    }
}

echo
echo "This script will $SCRIPT_PURPOSE the dotfiles:"
echo " └─from $SOURCE_DIR/"
echo "   └─to $TARGET_DIR/"
echo

# red color
r=$(tput setaf 1)
# green color
g=$(tput setaf 2)
# yellow color
y=$(tput setaf 3)
# blue color
b=$(tput setaf 4)
# magenta color
m=$(tput setaf 5)
# cyan color
c=$(tput setaf 6)
# white color
w=$(tput setaf 7)
# bright black color
gr=$(tput setaf 8)
cl=$(tput op)

echo "Copying files..."

file_list_len=$(jq '. | length' $file_list)
[[ $? -eq 1 ]] && exit_error "Error parsing $file_list json"

for (( i=0; i<$file_list_len; ++i)); do
    curr_name=$(jq -r .[$i].name $file_list)
    curr_dir=$(jq -r .[$i].dir $file_list)
    curr_file_list=$(jq -r .[$i].files[] $file_list)

    mkdir -p $curr_dir 2>/dev/null

    echo ""
    echo "$c$curr_name$cl: $curr_dir"

    loop_clear=false

    for curr_file in ${curr_file_list}; do

        source_file=$SOURCE_DIR/$curr_dir/$curr_file
        source_file=${source_file//\/\//\/}
        target_file=$TARGET_DIR/$curr_dir/$curr_file
        target_file=${target_file//\/\//\/}

        # If ONLY_UPDATES is true and the target file is newer than the source
        # file
        [[ -n $ONLY_UPDATES && ! "$target_file" -ot "$source_file" ]] && {
            continue
        } || {
            loop_clear=true
        }

        # If the source file exists
        se=$([ -f $source_file ] && {
                 printf '%s' "$g[FOUND]$cl"
             } || { # If the source file doesen't exist
                 printf '%s' "$r[MISSING]$cl"
             })
        te=$([[ ! "$target_file" -ot "$source_file" \
                    || ! -f $source_file ]] && {
                 printf '%s' "$g[NOT UPDATING]$cl"
             } || {
                 [ -f "$target_file" ] && {
                     printf '%s' "$r[UPDATING]$cl"
                 } || {
                     printf '%s' "$r[MISSING-COPYING]$cl"
                 }
             })

        cp --update $source_file $target_file
        [[ $? -ne 0 ]] && exit_error "error copying $curr_file"

        echo " │"
        echo " ├──$curr_file"
        echo " │   ├─${m}source$cl $se"
        echo " │   └─${y}target$cl $te"

    done

    [ $loop_clear = "true" ] && {
        # Last element clearing
        tput cuu1
        echo -e "\r  "
        tput cuu1
        tput cub1
        echo -e "\r  "
        tput cuu1
        tput cub1
        echo -e "\r └"
        tput cud 2
    } || {
        echo -e "No files updated for $curr_name"
    }

done

printf "\nDone!\n"
