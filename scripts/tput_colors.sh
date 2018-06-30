#!/usr/bin/env bash

# tput_colors - Demonstrate color combinations.
# Source: http://linuxcommand.org/lc3_adv_tput.php

# If there are colors in the arguments
[ $# -ge 1 ] && {
    fromhex(){
        hex=${1#"#"}
        r=$(printf '0x%0.2s' "$hex")
        g=$(printf '0x%0.2s' ${hex#??})
        b=$(printf '0x%0.2s' ${hex#????})
        printf '%03d' "$(( (r<75?0:(r-35)/40)*6*6 +
                       (g<75?0:(g-35)/40)*6   +
                       (b<75?0:(b-35)/40)     + 16 ))"
    }
    color(){
        echo "$(tput setab $1)     $(tput sgr0)"
    }
    for var in "$@"
    do
        tput_color=$(fromhex "$var")
        color ${tput_color}
    done
} || {

    for fg_color in {0..7}; do
        set_foreground=$(tput setaf $fg_color)
        for bg_color in {0..7}; do
            set_background=$(tput setab $bg_color)
            echo -n $set_background$set_foreground
            printf ' F:%s B:%s ' $fg_color $bg_color
        done
        echo $(tput sgr0)
    done
}
