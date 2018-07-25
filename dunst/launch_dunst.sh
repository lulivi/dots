#!/usr/bin/env bash

pkill dunst

# Update custom color file if older than the config file
if [ "$HOME/.config/dunst/dunstrc_xr_colors"\
         -ot "$HOME/.config/dunst/dunstrc" ]; then
    exec "$HOME/scripts/dunst_xr_theme_changer.sh"
fi

if [ -f "$HOME/.config/dunst/dunstrc_xr_colors" ]; then
    dunst -config "$HOME/.config/dunst/dunstrc_xr_colors" &
    echo "encuentra xcolors"
else
    dunst -config "$HOME/.config/dunst/dunstrc" &
fi
