#!/usr/bin/env sh

change_bg() {
    pkill swaybg
    swaybg -i "$(find ~/Pictures/pixelart/ -type f | shuf -n1)" -m fill &>/dev/null &
}

if [ "$1" != '--auto' ]; then
    change_bg
    exit 0
fi

while true; do
    change_bg
    sleep 600
done
