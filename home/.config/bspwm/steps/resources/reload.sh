#!/usr/bin/env sh

RESOURCES_DIR="$( cd "$( dirname "$0" )" && pwd )"

notify-send -a Bspwm "Restarting bspwm..."

"$RESOURCES_DIR/../../bspwmrc"
