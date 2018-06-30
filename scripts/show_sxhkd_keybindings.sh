#!/usr/bin/env bash

sxhkd_conf_file=$HOME/.config/sxhkd/sxhkdrc


space='^[[:space:]]'

new_key_binding=1

b=$(tput setaf 4)
rc=$(tput op)

echo "Commands:"

mapfile -t file_data < "$sxhkd_conf_file"
for line in "${file_data[@]}"; do
    # If the line doesn't start with '#'
    [[ "$line" =~ ^[^\#] ]] && {
        # If the line starts with space
        [[ "$line" =~ $space ]] && {
            printf '%s\n' "$line"
        } || { # If the line starts without spaces
            printf '%s\n' "$line"
        }
    } || {
        [[ "$line" =~ ^\#\# ]] && {
            printf '\n%s%s%s\n' "$b" "${line/\#\# /}" "$rc"
        }
    }
done
