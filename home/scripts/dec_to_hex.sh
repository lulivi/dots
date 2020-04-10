#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>

dec_to_hex () {
    [[ $1 =~ [0-9]{1,3} && 0 -le $1 && $1 -le 255 ]] && {
        printf "%x\n" $1
    } || {
        echo "Error"
    }
}

echo "Press q to exit program"
while true; do
    read -p "Decimal to Hex: " ans
    case $ans in
        q ) exit
            ;;
        * ) dec_to_hex $ans
            ;;
    esac
done
