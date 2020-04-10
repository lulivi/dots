#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>
# Dependences: dialog

DIALOG=${DIALOG=dialog}
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --clear --title "Session" \
        --menu "What do you want to do?:" 10 30 10 \
        "S" "Suspend" \
        "P" "Power off" \
        "R" "Reboot" 2> $tempfile

retval=$?

choice=`cat $tempfile`

case $retval in
  0)
    case $choice in
      "S") suspend;;
      "P") poweroff;;
      "R") reboot;;
    esac;;
  1) ;;
  255) ;;
esac
