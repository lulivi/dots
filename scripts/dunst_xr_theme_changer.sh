#!/usr/bin/env bash
###############################################################################
#
# This script creates a dunst user configuration file in
# $XDG_CONFIG_HOME/dunst/ folder, changing dunst basic teeming options
# according to your current X resources color palette.
#
# It gets your current user configuration file
# -$HOME/.conf/dunst/dunstrc, which is copied from the default
# config file in /usr/share/dunst/dunstrc if it does not exist- and
# changes the defined attributes -declared further on in the script as
# $theme_attr_dict dictionary- to the new ones. Then it dumps the new
# configuration to $user_xr_color_conf file.
#
###############################################################################

set -e

script_name="$(basename $0)"

# Function to get resource values
xrdb_get () {
    output=$(xrdb -q | grep -e "$1" | cut -f2)
    default="$2"
    printf '%s' "${output:-$default}"
}

# Default config dir and file
example_conf_dir="/usr/share/dunst"
example_conf="$example_conf_dir/dunstrc"

if [ -d "/usr/share/dunst" ]; then
    # Archlinux default dir and file
    example_conf_dir="/usr/share/dunst"

    if [ -f "$example_conf_dir/dunstrc" ]; then
        example_conf="$example_conf_dir/dunstrc"
    else
        printf 'Could not find the example config file in %s.
               \nPlease, change \$example_conf variable in the script' "$example_conf_dir"
        exit 1
    fi

elif [ -d "/usr/share/doc/dunst" ]; then
    # Debian/Ubuntu default dir
    example_conf_dir="/usr/share/doc/dunst"

    if [ -f "$example_conf_dir/dunstrc.example.gz" ]; then
        # Ubuntu <= 17.10 and Debian <= 1.2.0-2 default file:
        example_conf="$example_conf_dir/dunstrc.example.gz"
    elif [ -f "$example_conf_dir/dunstrc.gz" ]; then
        # Ubuntu >= 18.04 and Debian >= 1.3.0-2 default file:
        example_conf="$example_conf_dir/dunstrc.gz"
    else
        printf 'Could not find the example config file in %s.
               \nPlease, change \$example_conf variable in the script' "$example_conf_dir"
        exit 1
    fi

else
    printf 'Could not find the example config directory.
           \nPlease, change \$example_conf_dir variable in the script'
    exit 1
fi

# User config dir and file
user_conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dunst"
user_conf="$user_conf_dir/dunstrc"

# User xresources color config file
user_xr_color_conf="$user_conf_dir/dunstrc_xr_colors"

# Check if the user config directory exists
if ! [ -d "$user_conf_dir" ]; then
    printf '%s\n' "$user_conf_dir folder doesn't exist, creating..."
    mkdir -p  "$user_conf_dir"
fi

# Check if the user config file exists
if ! [ -f "$user_conf" ]; then
    printf '%s does not exist.\n' "$user_conf"
    printf 'Copying default config to %s...\n' "$user_conf_dir"
    cp "$example_conf" "$user_conf_dir"
fi

# Regular expressions
re_section_line='^\[(.*)\]$'
re_empty_comment_line='(^$)|(^[[:space:]]*(\#)|(;))'
re_attribute_line='^([[:space:]]*)([_[:alnum:]]+)'

# Create an array with the file lines
mapfile -t conf < "$user_conf"

# Attributes dictionary.
# Format:
#     ["<section>-<attribute>"]="<value>|$(xrdb_get '<X_resource>' '<default>')"
#
# You have to ensure <attribute> exists in <section> in $user_conf file
declare -A theme_attr_dict=(
    ["global-font"]="$(xrdb_get '*.font:' 'Monospace') $(xrdb_get '*.font_size:' '11')"
    ["global-frame_width"]="$(xrdb_get '*.border_width' '1')"
    ["global-frame_color"]="\"$(xrdb_get 'color8:' '#65737e')\""

    ["urgency_low-background"]="\"$(xrdb_get 'color0:' '#2b303b')\""
    ["urgency_low-foreground"]="\"$(xrdb_get 'color4:' '#65737e')\""
    ["urgency_low-frame_color"]="\"$(xrdb_get 'color4:' '#65737e')\""

    ["urgency_normal-background"]="\"$(xrdb_get 'color0:' '#2b303b')\""
    ["urgency_normal-foreground"]="\"$(xrdb_get 'color2:' '#a3be8c')\""
    ["urgency_normal-frame_color"]="\"$(xrdb_get 'color2:' '#a3be8c')\""

    ["urgency_critical-background"]="\"$(xrdb_get 'color0:' '#2b303b')\""
    ["urgency_critical-foreground"]="\"$(xrdb_get 'color1:' '#bf616a')\""
    ["urgency_critical-frame_color"]="\"$(xrdb_get 'color1:' '#bf616a')\""
)

# Attributes dictionary keys.
valid_keys="${!theme_attr_dict[@]}"

# Iterate over the file lines
for idx in "${!conf[@]}"; do
    # Current line
    curr_line="${conf[$idx]}"
    # If we are in a new section:
    if [[ "$curr_line" =~ $re_section_line ]]; then
        curr_section="${BASH_REMATCH[1]}"
        continue
    fi
    # Skip the line if it is empty or has a comment
    if [[ "$curr_line" =~ $re_empty_comment_line ]]; then
        continue
    fi
    # Get the attribute in the current line
    [[ "$curr_line" =~ $re_attribute_line ]]
    curr_attr_name="${BASH_REMATCH[2]}"
    curr_sett_name="${curr_section}-${curr_attr_name}"
    # If the current attribute is not in our dictionary, continue
    case "$valid_keys" in
        *"$curr_sett_name"*)
            conf[$idx]="    ${curr_attr_name} = ${theme_attr_dict[$curr_sett_name]}"
            ;;
    esac
done

# Create a header for the xr_color config file
user_xr_color_conf_content="\
###################################
#
# Config file created with
# $script_name wrapper
#
###################################

"

# After everything is completed, write the new config to a file
user_xr_color_conf_content+="$(printf '%s\n' "${conf[@]}")"

printf '%s\n' "$user_xr_color_conf_content" > $user_xr_color_conf

printf '%s updated successfully.\n' "$user_xr_color_conf"

