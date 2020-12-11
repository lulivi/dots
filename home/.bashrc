#
# ~/.bashrc
#

[[ $- != *i* ]] && return

# Chow colored man-pages
export LESS_TERMCAP_mb=$(tput bold; tput setaf 2)
export LESS_TERMCAP_md=$(tput bold; tput setaf 6)
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4)
export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7)
export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
export LESS_TERMCAP_mr=$(tput rev)
export LESS_TERMCAP_mh=$(tput dim)
export LESS_TERMCAP_ZN=$(tput ssubm)
export LESS_TERMCAP_ZV=$(tput rsubm)
export LESS_TERMCAP_ZO=$(tput ssupm)
export LESS_TERMCAP_ZW=$(tput rsupm)

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

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
        source "$subscript_path"
      else
        printf '[WARNING] "%s" does not exists or is not a shell script.\n' \
          "$subscript_path"
      fi
    done
  elif [ -r "$script_path" ]; then
    source "$script_path"
  else
    printf '[WARNING] "%s" does not exists or is not a shell script.\n' \
      "$script_path"
  fi
}

# Add item to a path-like variable
# Usage: add_paths_to_variable <path_var_name> <path_1> [<path_2> [...]]
add_paths_to_variable() {
  local path_variable_name="$1"
  shift 1
  local new_paths=("$@")

  for new_path in ${new_paths[@]}; do
    if [[ ${!path_variable_name} != *$new_path* ]]; then
      export $path_variable_name="$new_path":${!path_variable_name}
    else
      printf '[WARNING] "%s" path already in $%s.\n' \
        "$new_path" \
        "$path_variable_name"
    fi
  done
}

# Remove an item from a path-like variable
# Usage: del_paths_from_variable <path_var_name> <path_1> [<path_2> [...]]
del_paths_from_variable() {
    local path_variable_name="$1"
    local path_variable_contents="${!path_variable_name}"
    shift 1
    local del_paths=("$@")
    local path_to_remove=""

    for del_path in ${del_paths[@]}; do
        scaped_del_path="${del_path//\//\\\/}"
        cleaned_del_path="${scaped_del_path//\./\\\.}"
        case "${!path_variable_name}" in
            (${cleaned_del_path}:*)
                path_to_remove="${cleaned_del_path}:"
                ;;
            (*:${cleaned_del_path}*)
                path_to_remove=":${cleaned_del_path}"
                ;;
            (*)
                printf '[WARNING] "%s" is not in "$%s"\n' \
                    "$del_path" \
                    "$path_variable_name"
                path_to_remove=""
                ;;
        esac
        path_variable_contents="${path_variable_contents/${path_to_remove}}"
    done
    export $path_variable_name="$path_variable_contents"
}

source_shell_scripts "$HOME/.shell_utilities"
add_paths_to_variable "PATH" \
    "$HOME/.local/bin/" \
    "$HOME/scripts/" \
    "$HOME/.gem/ruby/2.7.0/bin" \
    "$HOME/.luarocks/bin/" \
    "$HOME/.cargo/bin/"

[ -f $HOME/.cache/wal/sequences ] && (cat ~/.cache/wal/sequences &)

