#!/usr/bin/env bash
#
# ~/.bashrc
#

# Check if running in interactive mode, if not, GTFO
[[ $- != *i* ]] && return

# Bash options
shopt -s checkwinsize
shopt -s expand_aliases
shopt -s histappend

# Shell options
set -o ignoreeof
set -o vi

# Unbind Ctrl+s and Ctrl+q
stty -ixon -ixoff

complete -cf sudo
xhost +local:root >/dev/null 2>&1

# add_paths_to_variable - Add items to a path-like variable
# Usage: add_paths_to_variable <path_var_name> <path_1> [<path_2> [...]]
add_paths_to_variable() {
    local path_variable_name="$1"
    eval path_variable_contents="\$$path_variable_name"
    shift 1
    local new_paths="$*"

    for new_path in $new_paths; do
        [[ $path_variable_contents == *$new_path* ]] && {
            printf '[WARNING] "%s" path already in $%s.\n' "$new_path" "$path_variable_name"
            continue
        }
        path_variable_contents="$new_path":$path_variable_contents
    done

    export "$path_variable_name"="$path_variable_contents"
}

# del_paths_from_variable - Remove items from a path-like variable
# Usage: del_paths_from_variable <path_var_name> <path_1> [<path_2> [...]]
del_paths_from_variable() {
    local path_variable_name="$1"
    eval path_variable_contents="\$$path_variable_name"
    shift 1
    local del_paths="$*"
    local path_to_remove=""

    for del_path in $del_paths; do
        scaped_del_path="${del_path//\//\\\/}"
        cleaned_del_path="${scaped_del_path//\./\\\.}"
        case "$path_variable_contents" in
            ${cleaned_del_path}:*)
                path_to_remove="${cleaned_del_path}:"
                ;;
            *:${cleaned_del_path}*)
                path_to_remove=":${cleaned_del_path}"
                ;;
            *)
                printf '[WARNING] "%s" is not in "$%s"\n' "$del_path" "$path_variable_name"
                continue
                ;;
        esac
        path_variable_contents="${path_variable_contents/${path_to_remove}}"
    done

    export "$path_variable_name"="$path_variable_contents"
}

# Define the common paths
add_paths_to_variable "PATH" \
  "$HOME/.local/bin/" \
  "$HOME/.gem/ruby/2.7.0/bin" \
  "$HOME/.luarocks/bin/" \
  "$HOME/.cargo/bin/" \
  "$HOME/.screenlayout/" \
  "$HOME/bin/"

# Load util shell scripts
for shell_script in "$HOME/.config/bash/"*.sh; do
    # shellcheck source=/dev/null
    [ -r "$shell_script" ] && . "$shell_script"
done

# Bash completions
[ -r /usr/share/bash-completion/bash_completion ] && {
    # shellcheck source=/dev/null
    . /usr/share/bash-completion/bash_completion
}

# Colourize ls output
if [[ -f ~/.dir_colors && -n "$(cat ~/.dir_colors)" ]]; then
    dircolors_file="$HOME/.dir_colors"
elif [[ -f /etc/DIR_COLORS && -n "$(cat /etc/DIR_COLORS)" ]]; then
    dircolors_file="/etc/DIR_COLORS"
fi
eval "$(dircolors -b ${dircolors_file})"
unset dircolors_file

# Theming
if [ -f "$HOME/.cache/wal/sequences" ]; then
    (cat "$HOME/.cache/wal/sequences" &)
fi

