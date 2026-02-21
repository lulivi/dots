#!/usr/bin/env sh

RESOURCES_DIR="$(dirname "$(realpath $0)")"

"$RESOURCES_DIR/teardown.sh"
bspc quit
