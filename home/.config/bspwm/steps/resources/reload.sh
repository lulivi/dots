#!/usr/bin/env sh

RESOURCES_DIR="$(dirname "$(realpath $0)")"

notify-send -a Bspwm "Restarting bspwm..."

"$RESOURCES_DIR/../../bspwmrc"
