#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>
# Dependences: dialog

# WM prompt
DIALOG=${DIALOG=dialog}
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --clear --title "Window Manager Selector" \
        --menu "Choose the WM to start:" 10 30 10 \
        "A" "AwesomeWM" \
        "G" "Gnome3" 2> $tempfile

retval=$?

choice=`cat $tempfile`

case $retval in
  0)
    echo "Starting the WM..."
    case $choice in
      "G") startx ~/.xinitrc;;
      "A") startx ~/.config/awesome/xinitrc;;
    esac;;
  1) ;;
  255) ;;
esac
