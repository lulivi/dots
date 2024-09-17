#!/usr/bin/env sh

#        d8888 888     888 88888888888 .d88888b.
#       d88888 888     888     888    d88P" "Y88b
#      d88P888 888     888     888    888     888
#     d88P 888 888     888     888    888     888
#    d88P  888 888     888     888    888     888
#   d88P   888 888     888     888    888     888 888888
#  d8888888888 Y88b. .d88P     888    Y88b. .d88P
# d88P     888  "Y88888P"      888     "Y88888P"
#
#  .d8888b. 88888888888     d8888 8888888b. 88888888888
# d88P  Y88b    888        d88888 888   Y88b    888
# Y88b.         888       d88P888 888    888    888
#  "Y888b.      888      d88P 888 888   d88P    888
#     "Y88b.    888     d88P  888 8888888P"     888
#       "888    888    d88P   888 888 T88b      888
# Y88b  d88P    888   d8888888888 888  T88b     888
#  "Y8888P"     888  d88P     888 888   T88b    888

STEPS_DIR="$(cd "$(dirname "$0")" && pwd)"
RESOURCES_DIR="$STEPS_DIR/resources/"

"$RESOURCES_DIR/teardown.sh"

# Wallpaper
feh --no-fehbg --randomize --bg-scale $HOME/img/backgrounds

# Compositor
compton -b --xrender-sync --xrender-sync-fence &

# Key-bindings
sxhkd &

# Notifications
dunst &

# Bar
make --directory "$RESOURCES_DIR/wmutils" dist

polybar --list-monitors | while read monitor ;do
    bar=secondary
    case $monitor in
        *primary*) bar=primary ;;
    esac
    POLYBAR_MONITOR="${monitor%%:*}" polybar "$bar" &
done
