#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>

Xr_themes_dir=$HOME/.themes/base16-xresources/xresources
Xr_base_theme_file=$HOME/.Xresources.theme
Xr_reloader=~/scripts/xresources_wrapper_reloader.sh

repo_base_url="https://github.com/chriskempson"
repo_name="base16-xresources"
repo_zip_url="$repo_base_url/$repo_name/archive/master.zip"
repo_clone_url="$repo_base_url/$repo_name.git"

[ -d "$Xr_themes_dir" ] || {
    echo "The Base16 Xresources theme folder does not exists in $HOME/.themes."
    echo "Do you want to download the themes and save them un $HOME/.themes?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes )
                mkdir -p $HOME/.themes/
                [ "$(which git 2>/dev/null)" ] && {
                    git clone $repo_clone_url $HOME/.themes/
                } || {
                    [ "$(which curl 2>/dev/null)" ] &&
                            [ "$(which unzip 2>/dev/null)" ] && {
                        cd $HOME/.themes
                        curl $repo_zip_url -O -J -L
                        unzip $repo_name
                    }
                }
                break
                ;;
            No )
                echo -n "Then, change the themes forlder var (Xr_themes_dir) "
                echo "in the script and run it again."
        esac
    done
}

exit_error () {
    echo "ERROR: $1"
    exit 1
}

[ $1 ] && {
    THEME_NAME="$1"
} || {
    [ $BASE16_THEME ] && {
        THEME_NAME="$BASE16_THEME"
    } || {
        exit_error "No arguments and var BASE16_THEME undefined or empty"
    }
}

Xr_new_theme_file="$Xr_themes_dir/base16-$THEME_NAME-256.Xresources"

[ -f "$Xr_new_theme_file" ] || {
    exit_error "$Xr_new_theme_file not found"
}

# Copy the defines of the selected theme to $HOME/.Xresources.theme
grep -e "^#define base" $Xr_new_theme_file > $Xr_base_theme_file

b="tput setaf 3"
cl="tput op"
echo "Xresources theme changed to $($b)$THEME_NAME$($cl)."

# Reload resources and call the wrapper around cpp (to create
# .Xresources). Obtained from:
#    Author: Olivier Mengué <dolmen@cpan.org>
#    https://github.com/dolmen/Xresources.edit
touch $HOME/.Xresources.src
[ ! -f "$HOME/.Xresources" -o \
        "$HOME/.Xresources.src" -nt \
        "$HOME/.Xresources" ] && {
    xrdb -cpp "$HOME/.Xresources.edit" "$HOME/.Xresources.src"
    echo "Xresources updated"
}
touch $HOME/.Xresources.src
