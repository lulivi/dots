#!/usr/bin/env bash
# Author: Olivier Mengué <dolmen@cpan.org>
# https://github.com/dolmen/Xresources.edit

# Reload resources and call ourself as a wrapper around cpp (to create
# .Xresources)
touch $HOME/.Xresources.src
[ ! -f "$HOME/.Xresources" -o \
        "$HOME/.Xresources.src" -nt \
        "$HOME/.Xresources" ] && {
    xrdb -cpp "$HOME/.Xresources.edit" "$HOME/.Xresources.src"
    echo "Xresources updated"
}
touch $HOME/.Xresources.src
