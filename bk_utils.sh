#!/usr/bin/env bash

#
# Colors
#
rcolor() {
    printf '%s%s%s' "$(tput setaf 1)" "$1" "$(tput op)"
}

gcolor() {
    printf '%s%s%s' "$(tput setaf 2)" "$1" "$(tput op)"
}

ycolor() {
    printf '%s%s%s' "$(tput setaf 3)" "$1" "$(tput op)"
}

bcolor() {
    printf '%s%s%s' "$(tput setaf 4)" "$1" "$(tput op)"
}

# Outputs a warn message (yellow color)
warn_msg() {
    if [ -z "$quiet" ]; then
        printf '%s%s\n' "$(ycolor "$1")" "$cl"
    fi
}

# Outputs an error message (red color)
err_msg() {
    printf '%s%s\n' "$(rcolor "$1")" "$cl"
}

# Ingore lines that match with
re_empty_comment_line='(^$)|(^\s*\#)'
# Only match lines with the following regular expression
re_file_line='^([[:alnum:]_/.-]+)\s*->\s*([[:alnum:]_/.~-]+)$'

# Read backup/restore file list
#
# This function reads the list of files to backup/restore.
read_dot_file_list () {
    # Read the backup/restore file list
    mapfile -t bk_file_content < "$dot_file_list"

    # Iterate over the file lines
    for idx in "${!bk_file_content[@]}"; do
        curr_line="${bk_file_content[$idx]}"
        # Skip comment or blank lines
        if [[ "$curr_line" =~ $re_empty_comment_line ]]; then continue; fi
        # Check for errors in the current line format
        if ! [[ "$curr_line" =~ $re_file_line ]]; then
            warn_msg "Incorrect format in $((idx+1)) line. Ignoring."
            continue
        fi
        # Left side: Repo path to file
        repo_path="${BASH_REMATCH[1]}"
        # Right side: Home path to file
        home_path="${BASH_REMATCH[2]//\~/$HOME}"

        # Add the current line repo path and status
        repo_paths+=("$BASE_DIR/$repo_path")
        if [ -f "$repo_path" ]; then
            : "$(gcolor "E-F")"
        elif [ -d "$repo_path" ]; then
            : "$(bcolor "E-D")"
        else
            : "$(rcolor "MSS")"
        fi
        repo_stats+=("$_")

        # Add the current line home path and status
        home_paths+=("$home_path")
        if [ -L "$home_path" ]; then
            : "$(ycolor "E-L")"
        elif [ -f "$home_path" ]; then
            : "$(gcolor "E-F")"
        elif [ -d "$home_path" ]; then
            : "$(bcolor "E-D")"
        else
            : "$(rcolor "MSS")"
        fi
        home_stats+=("$_")
    done
}

# List file
#
# Show file info about source and target path
list_file() {
    repo_path="$1"
    repo_stat="$2"
    home_path="$3"
    home_stat="$4"
    ln_status="$5"
    ln_text=""

    if [ "$ln_status" ]; then
        case "$ln_status" in
            [0-9]+) # Is a number
                if [ "$ln_status" -gt "0" ]; then
                    : "ERR"
                else
                    : "O-K"
                fi
                ;;
            *) # Is a string
                : "$ln_status"
                ;;
        esac
        ln_text="$_"
    fi

    if [ -z "$quiet" ]; then
        printf '%s %s\n' "${repo_path##*\/}" "$ln_text"
        printf '  |- from [%s] %s/\n' \
               "${repo_stat}" \
               "${repo_path%/*}"
        printf '  |--- to [%s] %s/\n' \
               "${home_stat}" \
               "${home_path%/*}"
    else
        printf '[%s] -> [%s] %s %s\n' \
               "${repo_stat}" \
               "${home_stat}" \
               "${repo_path##*\/}" \
               "$ln_text"
    fi
}

# Deploy file
#
# Perform deployment of a file using ln to create a symbolic link
deploy_file() {
    repo_path="$1"
    repo_stat="$2"
    home_path="$3"
    home_stat="$4"

    if [[ -f "$repo_path" || -d "$repo_path" ]] &&\
           [ "$repo_path" == "$(readlink "$home_path")" ]; then
        list_file "$repo_path" \
                  "$repo_stat" \
                  "$home_path" \
                  "$home_stat" \
                  "$(gcolor DONE)"
    else
        if [[ -f "$repo_path" || -d "$repo_path" ]]; then
            # If the target file does not exist create al symbolic link of
            # it
            if ! [ -e "$home_path" ]; then
                # Link the file
                ln -s "$repo_path" "$home_path"
                list_file "$repo_path" \
                          "$repo_stat" \
                          "$home_path" \
                          "$home_stat" \
                          "$?"
            else
                if [ -L "$home_path" ]; then
                    if [ "$repo_path" \
                             == "$(readlink -n "$home_path")" ]; then
                        warn_msg "File $home_path exists and it is a \
link. Ignoring."
                    else
                        err_msg "File $home_path exists, it is a link \
but does not point to ${repo_paths[$idx]}. Remove it manually."
                    fi
                else
                    err_msg "File $home_path exists, but it is not a link, remove \
it and try again."
                fi
            fi
        else
            err_msg "File ${repo_paths[$idx]} not found."
        fi
    fi
}

# Remove link
#
# Perform link removal
remove_link() {
    repo_path="$1"
    home_path="$2"

    if [ -L "$home_path" ]; then
        if [ "$repo_path" \
                 == "$(readlink "$home_path")" ]; then
            # rm "$home_paths"
            if [ "$?" -eq "0" ]; then
                if [ -z "$quiet" ]; then
                    printf '[%s] %s\n' "$(rcolor REM)" "${home_path##*\/}"
                    printf ' |- from %s\n' "$home_path"
                else
                    printf '[%s] %s\n' "$(rcolor REM)" "${home_path##*\/}"
                fi
            else
                err_msg "[ERR] $home_path"
            fi
        else
            err_msg "$home_path does not point to \
$repo_path."
        fi
    else
        warn_msg "$home_path is not a symbolic link or does \
not exist, ignoring."
    fi
}
