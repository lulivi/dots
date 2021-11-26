#
# ~/.bashrc
#

[[ $- != *i* ]] && return

[ -r /usr/share/bash-completion/bash_completion ] && {
  . /usr/share/bash-completion/bash_completion
}

use_color=true

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?} # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs} ]] &&
  type -P dircolors >/dev/null &&
  match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color}; then
  # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
  if type -P dircolors >/dev/null; then
    if [[ -f ~/.dir_colors ]]; then
      eval $(dircolors -b ~/.dir_colors)
    elif [[ -f /etc/DIR_COLORS ]]; then
      eval $(dircolors -b /etc/DIR_COLORS)
    fi
  fi
fi

unset use_color safe_term match_lhs

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

source_shell_scripts "$HOME/.config/bash/"
. $HOME/scripts/add_paths_to_variable.sh "PATH" \
    "$HOME/.local/bin/" \
    "$HOME/scripts/" \
    "$HOME/.gem/ruby/2.7.0/bin" \
    "$HOME/.luarocks/bin/" \
    "$HOME/.cargo/bin/" \
    "$HOME/.screenlayout/"

[ -f $HOME/.cache/wal/sequences ] && (cat ~/.cache/wal/sequences &)

