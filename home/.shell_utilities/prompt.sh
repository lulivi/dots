# Colors
# _C_BLACK="$(tput setaf 0)"
# _C_D_GRAY="$(tput bold; tput setaf 0)"
# _C_RED="$(tput setaf 1)"
_C_L_RED="$(tput bold; tput setaf 1)"
# _C_GREEN="$(tput setaf 2)"
_C_L_GREEN="$(tput bold; tput setaf 2)"
# _C_YELLOW="$(tput setaf 3)"
# _C_L_YELLOW="$(tput bold; tput setaf 3)"
_C_BLUE="$(tput setaf 4)"
# _C_L_BLUE="$(tput bold; tput setaf 4)"
# _C_MAGENTA="$(tput setaf 5)"
_C_L_MAGENTA="$(tput bold; tput setaf 5)"
# _C_CYAN="$(tput setaf 6)"
_C_L_CYAN="$(tput bold; tput setaf 6)"
# _C_L_GRAY="$(tput setaf 7)"
# _C_WHITE="$(tput bold; tput setaf 7)"
_C_R="$(tput sgr0)"

# Set the return code in _STATUS_CODE
__set_status_code() {
  if [[ $1 -ne 0 ]]; then
    : "${_C_L_RED}${1}${_C_R} "
  else
    : ""
  fi
  _STATUS_CODE="$_"
}

# Obtain a path relative to $1
__relative() {
  printf "$(realpath --relative-to="$1" "$2")"
}

# Determine active Python virtualenv details.
__set_virtualenv() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    : "${_C_BLUE}["$(__relative "$(pwd)" "$VIRTUAL_ENV")"] ${_C_L_MAGENTA}[$(python --version)]${_C_R} "
  else
    : ""
  fi
  _VIRTUAL_ENV="$_"
}

# Set the working directory _WORKING_DIR
__set_working_dir() {
  _WORKING_DIR="$_C_L_CYAN[\w]$_C_R"
}

# Set the git prompt in _GIT_PROMPT
__set_git_prompt() {
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [[ -n "$BRANCH" ]]; then
    REPOSITORY="$(basename -s .git "$(git config --get remote.origin.url)")"
    : "${_C_L_GREEN}[${REPOSITORY}@${BRANCH}]${_C_R}"
  else
    : ""
  fi
  _GIT_PROMPT="$_"
}

# Set the full bash prompt.
__set_bash_prompt() {
  # Set the _STATUS_CODE_VAR variable.
  __set_status_code "$?"

  # Set the _VIRTUAL_ENV variable.
  __set_virtualenv

  # Set the _WORKING_DIR variable
  __set_working_dir

  # Set the _GIT_PROMPT_VAR variable
  __set_git_prompt

  # Set the bash prompt variable.
  PS1="$_STATUS_CODE$_VIRTUAL_ENV$_WORKING_DIR $_GIT_PROMPT\n> "
}

# Tell bash to execute this function just before displaying its prompt.
PROMPT_COMMAND=__set_bash_prompt

# Set a basic cprompt
set_basic_prompt() {
  __set_working_dir

  PS1="$_WORKING_DIR\n> "

  unset PROMPT_COMMAND
}

# Set a complete prompt
set_complete_prompt() {
  PROMPT_COMMAND=__set_bash_prompt
}

