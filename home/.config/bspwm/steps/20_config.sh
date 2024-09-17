#!/usr/bin/env sh

#  .d8888b.   .d88888b.  888b    888 8888888888 8888888 .d8888b. 
# d88P  Y88b d88P" "Y88b 8888b   888 888          888  d88P  Y88b
# 888    888 888     888 88888b  888 888          888  888    888
# 888        888     888 888Y88b 888 8888888      888  888       
# 888        888     888 888 Y88b888 888          888  888  88888
# 888    888 888     888 888  Y88888 888          888  888    888
# Y88b  d88P Y88b. .d88P 888   Y8888 888          888  Y88b  d88P
#  "Y8888P"   "Y88888P"  888    Y888 888        8888888 "Y8888P88

bspc config normal_border_color   #2b303b
bspc config active_border_color   #2b303b
bspc config focused_border_color  #65737e
bspc config presel_feedback_color #ebcb8b

bspc config border_width          3
bspc config window_gap            5

bspc config split_ratio           0.52
bspc config borderless_monocle    false
bspc config gapless_monocle       true
bspc config focus_follows_pointer true
