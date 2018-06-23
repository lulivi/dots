#!/usr/bin/env bash
# Modified script from https://github.com/chriskempson/base16-shell/

ESC_F="\x1b[38;5;"
ESC_B="\x1b[48;5;"
RES_C="\x1b[0m"

theme=$HOME/.Xresources.theme
[ -f $theme ] && {
    color_list=($(xrdb -query | grep -e "color[0-9]" | cut -f2 | tr '\n' ' '))
} || {
    printf "No theme file %s found\n" $theme
    exit 1
}

ansi_mappings=(
    Black
    Red
    Green
    Yellow
    Blue
    Magenta
    Cyan
    White
    Bright_Black
    Bright_Red
    Bright_Green
    Bright_Yellow
    Bright_Blue
    Bright_Magenta
    Bright_Cyan
    Bright_White
)
base_names=(
    base00
    base08
    base0B
    base0A
    base0D
    base0E
    base0C
    base05
    base03
    base08
    base0B
    base0A
    base0D
    base0E
    base0C
    base07
    base09
    base0F
    base01
    base02
    base04
    base06
)

for padded_value in `seq -w 0 21`; do
    # non_paded_value=10 if padded_value == 10; 02 if padded_value == 2
    non_padded_value=$((10#$padded_value))
    # current_color=#ea51b2
    current_color=${color_list[$non_padded_value]}
    # base16_color_name="base0B"
    base16_color_name=${base_names[$non_padded_value]}
    # current_color_label="color02" or "unknown"
    current_color_label=${current_color:-unknown}
    # ansi_label="Green"
    ansi_label=${ansi_mappings[$non_padded_value]}
    # block=<tput setb 2>
    block=$(printf "$ESC_B${non_padded_value}m_______________________")
    # foreground<tput setf 2>${color_variable}
    foreground=$(printf "$ESC_F${non_padded_value}m$color_variable")
    printf "%s%s %s$RES_C %-30s %s%s\x1b[0m\n" \
           $base16_color_name \
           $foreground \
           $current_color_label \
           ${ansi_label:-""} \
           $foreground \
           $block;
done;
