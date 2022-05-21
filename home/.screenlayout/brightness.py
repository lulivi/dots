#!/bin/sh

_LEVEL="${1:-0.8}"
_MONITORS="$(xrandr --listactivemonitors | awk '{print $4}')"

for monitor in $_MONITORS; do
    xrandr --output "$monitor"  --brightness "$_LEVEL" >/dev/null  2>&1
done

