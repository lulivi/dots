#!/usr/bin/env bash

# tput_colors - Demonstrate color combinations.
# Source: http://linuxcommand.org/lc3_adv_tput.php

for fg_color in {0..7}; do
    set_foreground=$(tput setaf $fg_color)
    for bg_color in {0..7}; do
        set_background=$(tput setab $bg_color)
        echo -n $set_background$set_foreground
        printf ' F:%2s B:%2s ' $fg_color $bg_color
    done
    echo $(tput sgr0)
done

for fg_color in {8..15}; do
    set_foreground=$(tput setaf $fg_color)
    for bg_color in {8..15}; do
        set_background=$(tput setab $bg_color)
        echo -n $set_background$set_foreground
        printf ' F:%2s B:%2s ' $fg_color $bg_color
    done
    echo $(tput sgr0)
done