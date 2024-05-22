# Directories
export CURRENT_THEME_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
export CURRENT_THEME_MODULES_DIR="$CURRENT_THEME_DIR/modules"
export CURRENT_THEME_STATIC_DIR="$CURRENT_THEME_DIR/static"
export CURRENT_THEME_TEMPLATES_DIR="$CURRENT_THEME_DIR/templates"
export THEMES_UTILS_DIR="$(dirname "$CURRENT_THEME_DIR")/utils"
# Files
export LEFTWM_THEME_LOG_FILE="/tmp/leftwm-theme-log"
export LEMONBAR_MAIN_PIPE="/tmp/lemonbar-main-fifo"
# Functions
debug_log() {
    local msg="$1"
    printf '********\n%s\n' "$msg" >> $LEFTWM_THEME_LOG_FILE
}