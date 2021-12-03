#
# ~/.bashrc
#

# Check if running in interactive mode, if not, GTFO
[[ $- != *i* ]] && return

# Bash completions
[ -r /usr/share/bash-completion/bash_completion ] && {
  . /usr/share/bash-completion/bash_completion
}

# Colourize ls output
if [[ -f ~/.dir_colors && -n "$(cat ~/.dir_colors)" ]]; then
  dircolors_file="$HOME/.dir_colors"
elif [[ -f /etc/DIR_COLORS && -n "$(cat /etc/DIR_COLORS)" ]]; then
  dircolors_file="/etc/DIR_COLORS"
fi
eval $(dircolors -b ${dircolors_file})
unset dircolors_file

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

# Define the common paths
. $HOME/.sh/add_paths_to_variable.sh "PATH" \
  "$HOME/.local/bin/" \
  "$HOME/.bin/" \
  "$HOME/.gem/ruby/2.7.0/bin" \
  "$HOME/.luarocks/bin/" \
  "$HOME/.cargo/bin/" \
  "$HOME/.screenlayout/"

# Load all shell utils: variables, aliases and functions
. $HOME/.sh/load_shell_scripts.sh "$HOME/.config/bash/"

# Theming
[ -f $HOME/.cache/wal/sequences ] && (cat ~/.cache/wal/sequences &)

