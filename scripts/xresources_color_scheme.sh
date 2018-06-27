#!/usr/bin/env bash
# Modified script from https://github.com/chriskempson/base16-shell/

r=$(tput op)

htc=$HOME/scripts/hex_dec_color.sh

color_list=($(xrdb -query | grep -e "color[0-9]" | cut -f2 | tr '\n' ' '))


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

# Use tput colors to get the exact ones
for padded_value in $(seq -w 0 15); do
    # non_paded_value=10 if padded_value == 10; 02 if padded_value == 2
    non_padded_value=$((10#$padded_value))
    # current_color=#ea51b2
    current_color=${color_list[$non_padded_value]}
    # base16_color_name="base0B"
    base16_color_name=${base_names[$non_padded_value]}
    # hex_label="color02" or "unknown"
    hex_label=${current_color:-unknown}
    # ansi_label="Green"
    ansi_label=${ansi_mappings[$non_padded_value]}
    # Background color
    fc=$(tput setaf $non_padded_value)
    # Foreground color
    bc=$(tput setab $non_padded_value)
    # block=<tput setb 2>
    block=$(printf "${bc}${fc}_______$r")
    # foreground<tput setf 2>${color_variable}
    printf "color%-2s %s %s %s %s\n" \
           $non_padded_value \
           $base16_color_name \
           $hex_label \
           $block \
           ${ansi_label:-""}
done

# Use tput colors to get look-alikes ones
for padded_value in $(seq -w 16 21); do
    # non_paded_value=10 if padded_value == 10; 02 if padded_value == 2
    non_padded_value=$((10#$padded_value))
    # current_color=#ea51b2
    current_color=${color_list[$non_padded_value]}
    # base16_color_name="base0B"
    base16_color_name=${base_names[$non_padded_value]}
    # hex_label="color02" or "unknown"
    hex_label=${current_color:-unknown}
    # ansi_label="Green"
    ansi_label=${ansi_mappings[$non_padded_value]}
    # Foreground color
    fc=$($htc -f $hex_label)
    # Background color
    bc=$($htc -b $hex_label)
    # block=<tput setb 2>
    block=$(printf "${bc}${fc}_______$r")
    # foreground<tput setf 2>${color_variable}
    printf "color%-2s %s %s %s %s\n" \
           $non_padded_value \
           $base16_color_name \
           $hex_label \
           $block \
           ${ansi_label:-""}
done
