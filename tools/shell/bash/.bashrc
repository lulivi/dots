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

# Colors
_C_BLACK="$(tput setaf 0)"
_C_D_GRAY="$(tput bold; tput setaf 0)"
_C_RED="$(tput setaf 1)"
_C_L_RED="$(tput bold; tput setaf 1)"
_C_GREEN="$(tput setaf 2)"
_C_L_GREEN="$(tput bold; tput setaf 2)"
_C_YELLOW="$(tput setaf 3)"
_C_L_YELLOW="$(tput bold; tput setaf 3)"
_C_BLUE="$(tput setaf 4)"
_C_L_BLUE="$(tput bold; tput setaf 4)"
_C_MAGENTA="$(tput setaf 5)"
_C_L_MAGENTA="$(tput bold; tput setaf 5)"
_C_CYAN="$(tput setaf 6)"
_C_L_CYAN="$(tput bold; tput setaf 6)"
_C_L_GRAY="$(tput setaf 7)"
_C_WHITE="$(tput bold; tput setaf 7)"
_C_R="$(tput sgr0)"

function __set_git_prompt() {
  BRANCH="$(git branch --show-current 2>/dev/null)"
  if [[ -n "$BRANCH" ]]; then
    REPOSITORY="$(basename -s .git "$(git remote get-url origin)")"
    if [[ -z "$(git status --short)" ]]; then
      : "[${_C_L_GREEN}${BRANCH}${_C_R}]"
    else
      : "[${_C_L_YELLOW}${BRANCH}${_C_R}]"
    fi
    if [[ -n "$REPOSITORY" ]]; then
      : "$_ [${_C_L_MAGENTA}${REPOSITORY}${_C_R}]"
    fi
  else
    : ""
  fi
  _GIT_PROMPT="$_"
}

function __set_status_code() {
  if [[ $1 -ne 0 ]]; then
    : "${_C_L_RED}${1}${_C_R} "
  else
    : ""
  fi
  _STATUS_CODE="$_"
}

function __relative() {
  printf "$(realpath --relative-to="$1" "$2")"
}

# Determine active Python virtualenv details.
function __set_virtualenv() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    : "${_C_BLUE}["$(__relative "$(pwd)" "$VIRTUAL_ENV")"]${_C_R} "
  else
    : ""
  fi
  _VIRTUAL_ENV="$_"
}

# Set the full bash prompt.
function set_bash_prompt() {
  # Set the _STATUS_CODE_VAR variable.
  __set_status_code "$?"

  # Set the _VIRTUAL_ENV variable.
  __set_virtualenv

  # Set the _GIT_PROMPT_VAR variable
  __set_git_prompt

  # Set the bash prompt variable.
  PS1="$_STATUS_CODE$_VIRTUAL_ENV$_C_L_CYAN[\w]$_C_R $_GIT_PROMPT\n> "
}

# Tell bash to execute this function just before displaying its prompt.
PROMPT_COMMAND=set_bash_prompt

# Bash options
shopt -s checkwinsize
shopt -s expand_aliases
shopt -s histappend

# Shell options
set -o ignoreeof

complete -cf sudo
xhost +local:root >/dev/null 2>&1

# Source a shell script
# Usage: source_shell_script <script_to_source>
source_shell_script() {
  local script_to_source="$1"

  if [ -r "$script_to_source" ]; then
    source "$script_to_source"
  else
    printf '[WARNING] "%s" does not exists or is not a shell script.\n' \
      "$script_to_source"
  fi
}

# Add item to a path-like variable
# Usage: add_path_to_variable <path_variable_name> <new_path>
add_path_to_variable() {
  local path_variable_name="$1"
  local new_path="$2"

  if [[ ${!path_variable_name} != *$new_path* ]]; then
    export $path_variable_name=$new_path:${!path_variable_name}
  else
    printf '[WARNING] "%s" path already in $%s.\n' \
      "$new_path" \
      "$path_variable_name"
  fi
}

source_shell_script "$HOME/.shell_utilities.sh"
source_shell_script "$HOME/.shell_aliases.sh"
source_shell_script "$HOME/.shell_variables.sh"

add_path_to_variable "PATH" "$HOME/scripts/"
add_path_to_variable "PATH" "$HOME/.local/bin/"


[ -f $HOME/.cache/wal/sequences ] && (cat ~/.cache/wal/sequences &)
