# Colors

# Foreground
_C_FG_BLACK='\x1b[30m'   # black
_C_FG_RED='\x1b[31m'     # red
_C_FG_GREEN='\x1b[32m'   # green
_C_FG_YELLOW='\x1b[33m'  # yellow
_C_FG_BLUE='\x1b[34m'    # blue
_C_FG_MAGENTA='\x1b[35m' # magenta
_C_FG_CYAN='\x1b[36m'    # cyan
_C_FG_WHITE='\x1b[37m'   # white

# Background
_C_BG_BLACK='\x1b[40m'   # black
_C_BG_RED='\x1b[41m'     # red
_C_BG_GREEN='\x1b[42m'   # green
_C_BG_YELLOW='\x1b[43m'  # yellow
_C_BG_BLUE='\x1b[44m'    # blue
_C_BG_MAGENTA='\x1b[45m' # magenta
_C_BG_CYAN='\x1b[46m'    # cyan
_C_BG_WHITE='\x1b[47m'   # white

# Style
_C_STYLE_BOLD='\x1b[1m'       # bold
_C_STYLE_BLINK='\x1b[5m'      # blink
_C_STYLE_RESET='\x1b(B\x1b[m' # reset

# Set the return code in _STATUS_CODE
__set_status_code() {
  [ $1 -ne 0 ] && {
    : "${_C_BG_RED}${_C_STYLE_BLINK}${_C_FG_BLACK}<Error: ${1}>${_C_STYLE_RESET} "
  } || {
    : ""
  }
  _STATUS_CODE="$_"
}

__set_timestamp() {
  _TIMESTAMP="$_C_FG_YELLOW[ $(date +%H:%M) ]$_C_STYLE_RESET"
}

# Obtain a path relative to $1
__relative() {
  printf "$(realpath --relative-to="$1" "$2")"
}

# Determine active Python virtualenv details.
__set_virtualenv() {
  [ -n "$VIRTUAL_ENV" ] && {
    local python_version="$(python --version)"
    : "${_C_FG_BLUE}[ "$(__relative "$(pwd)" "$VIRTUAL_ENV")"(${python_version#* }) ]${_C_STYLE_RESET} "
  } || {
    : ""
  }
  _VIRTUAL_ENV="$_"
}

# Set the working directory _WORKING_DIR
__set_working_dir() {
  _WORKING_DIR="$_C_FG_CYAN[ \w ]$_C_STYLE_RESET"
}

# Set the git prompt in _GIT_PROMPT
__set_git_prompt() {
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
__set_bash_prompt() {
  # Write the status code if an error has ocurred.
  __set_status_code "$?"
  # Add the timestamp.
  __set_timestamp
  # Show the python virtual environment and version.
  __set_virtualenv
  # Set the _WORKING_DIR variable
  __set_working_dir
  # Set the _GIT_PROMPT_VAR variable
  __set_git_prompt
  # Set the bash prompt variable.
  PS1=$(printf "$_STATUS_CODE$_TIMESTAMP $_VIRTUAL_ENV$_WORKING_DIR $_GIT_PROMPT\n> ")
}

# Tell bash to execute this function just before displaying its prompt.
PROMPT_COMMAND=__set_bash_prompt

# Set a basic cprompt
set_basic_prompt() {
  unset PROMPT_COMMAND

  __set_working_dir
  __set_timestamp

  PS1="$_TIMESTAMP $_WORKING_DIR\n> "
}

# Set a complete prompt
set_complete_prompt() {
  PROMPT_COMMAND=__set_bash_prompt
}

