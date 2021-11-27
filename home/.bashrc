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

# Source a shell scripts
# Usage: source_shell_scripts <path_to_script/path_to_dir>
source_shell_scripts() {
  local script_path="$1"

  if [ -d "$script_path" ]; then
    for subscript_path in $script_path/*.sh; do
      if [ -r "$subscript_path" ]; then
        . "$subscript_path"
      else
        printf '[WARNING] "%s" does not exists or is not a shell script.\n' \
          "$subscript_path"
      fi
    done
  elif [ -r "$script_path" ]; then
    . "$script_path"
  else
    printf '[WARNING] "%s" does not exists or is not a shell script.\n' \
      "$script_path"
  fi
}

# Load all the shell configuration files
source_shell_scripts "$HOME/.config/bash/"
. $HOME/scripts/add_paths_to_variable.sh "PATH" \
    "$HOME/.local/bin/" \
    "$HOME/scripts/" \
    "$HOME/.gem/ruby/2.7.0/bin" \
    "$HOME/.luarocks/bin/" \
    "$HOME/.cargo/bin/" \
    "$HOME/.screenlayout/"

[ -f $HOME/.cache/wal/sequences ] && (cat ~/.cache/wal/sequences &)

