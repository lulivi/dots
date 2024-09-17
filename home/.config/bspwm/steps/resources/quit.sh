#!/usr/bin/env sh

RESOURCES_DIR="$(cd "$(dirname "$0")" && pwd)"

"$RESOURCES_DIR/teardown.sh"
bspc quit
