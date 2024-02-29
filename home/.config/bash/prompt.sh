# Colors

# Foreground
_C_FG_BLACK="$(printf '\x1b[30m')"   # black
_C_FG_RED="$(printf '\x1b[31m')"     # red
_C_FG_GREEN="$(printf '\x1b[32m')"   # green
_C_FG_YELLOW="$(printf '\x1b[33m')"  # yellow
_C_FG_BLUE="$(printf '\x1b[34m')"    # blue
_C_FG_MAGENTA="$(printf '\x1b[35m')" # magenta
_C_FG_CYAN="$(printf '\x1b[36m')"    # cyan
_C_FG_WHITE="$(printf '\x1b[37m')"   # white

# Background
_C_BG_BLACK="$(printf '\x1b[40m')"   # black
_C_BG_RED="$(printf '\x1b[41m')"     # red
_C_BG_GREEN="$(printf '\x1b[42m')"   # green
_C_BG_YELLOW="$(printf '\x1b[43m')"  # yellow
_C_BG_BLUE="$(printf '\x1b[44m')"    # blue
_C_BG_MAGENTA="$(printf '\x1b[45m')" # magenta
_C_BG_CYAN="$(printf '\x1b[46m')"    # cyan
_C_BG_WHITE="$(printf '\x1b[47m')"   # white

# Style
_C_STYLE_BOLD="$(printf '\x1b[1m')"       # bold
_C_STYLE_BLINK="$(printf '\x1b[5m')"      # blink
_C_STYLE_RESET="$(printf '\x1b(B\x1b[m')" # reset

# Set the return code in _STATUS_CODE
__prompt_set_status_code() {
  [ $1 -ne 0 ] && {
    : "${_C_BG_RED}${_C_STYLE_BLINK}${_C_FG_BLACK}<Error: ${1}>${_C_STYLE_RESET} "
  } || {
    : ""
  }
  _STATUS_CODE="$_"
}

__prompt_set_timestamp() {
  _TIMESTAMP="$_C_FG_YELLOW[ $(date +%H:%M) ]$_C_STYLE_RESET"
}

# Determine active Python virtualenv details.
__prompt_set_virtualenv() {
  [ -n "$VIRTUAL_ENV" ] && {
    local python_version="$(python --version)"
    local relative_path="$(realpath --relative-to="$PWD" "$VIRTUAL_ENV")"
    : "${_C_FG_BLUE}[ $relative_path(${python_version#* }) ]${_C_STYLE_RESET} "
  } || {
    : ""
  }
  _VIRTUAL_ENV="$_"
}

# Set the working directory _WORKING_DIR
__prompt_set_working_dir() {
  if [ -n "$DISTROBOX_ENTER_PATH" ]; then
    _distrobox="${_C_FG_RED}DistroBox:${_C_FG_CYAN}"
  fi
  _WORKING_DIR="$_C_FG_CYAN[ ${_distrobox}\w ]$_C_STYLE_RESET"
}

# Set the git prompt in _GIT_PROMPT
__prompt_set_git_prompt() {
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [ -n "$BRANCH" ] && {
    REPOSITORY="$(basename -s .git "$(git config --get remote.origin.url)")"
    : "${_C_FG_GREEN}[ ${REPOSITORY}@${BRANCH} ]${_C_STYLE_RESET}"
  } || {
    : ""
  }
  _GIT_PROMPT="$_"
}

# Set the full bash prompt.
__set_complete_prompt() {
  # Write the status code if an error has ocurred.
  __prompt_set_status_code "$?"
  # Add the timestamp.
  __prompt_set_timestamp
  # Show the python virtual environment and version.
  __prompt_set_virtualenv
  # Set the _WORKING_DIR variable
  __prompt_set_working_dir
  # Set the _GIT_PROMPT_VAR variable
  __prompt_set_git_prompt
  # Set the bash prompt variable.
  PS1="$_STATUS_CODE$_TIMESTAMP $_VIRTUAL_ENV$_WORKING_DIR $_GIT_PROMPT\n> "
}

# Set a basic cprompt
set_basic_prompt() {
  unset PROMPT_COMMAND
  __prompt_set_timestamp
  __prompt_set_working_dir
  PS1="$_TIMESTAMP $_WORKING_DIR\n> "
}

# Set a complete prompt
set_complete_prompt() {
  PROMPT_COMMAND=__set_complete_prompt
}

# By default use a complete prompt
set_complete_prompt
