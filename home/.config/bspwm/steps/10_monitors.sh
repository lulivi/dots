#!/usr/bin/env sh

# 888b     d888  .d88888b.  888b    888 8888888 88888888888 .d88888b.  8888888b.   .d8888b.
# 8888b   d8888 d88P" "Y88b 8888b   888   888       888    d88P" "Y88b 888   Y88b d88P  Y88b
# 88888b.d88888 888     888 88888b  888   888       888    888     888 888    888 Y88b.
# 888Y88888P888 888     888 888Y88b 888   888       888    888     888 888   d88P  "Y888b.
# 888 Y888P 888 888     888 888 Y88b888   888       888    888     888 8888888P"      "Y88b.
# 888  Y8P  888 888     888 888  Y88888   888       888    888     888 888 T88b         "888
# 888   "   888 Y88b. .d88P 888   Y8888   888       888    Y88b. .d88P 888  T88b  Y88b  d88P
# 888       888  "Y88888P"  888    Y888 8888888     888     "Y88888P"  888   T88b  "Y8888P"

get_monitor_geometry () {
    local no_priority="${monitor%(*}"
    printf '%s' "${no_priority#*:}"
}

polybar --list-monitors | while read monitor; do
    monitor_name="${monitor%%:*}"
    monitor_geometry="$(get_monitor_geometry "$monitor")"
    case $monitor in
        (*primary*)
            notify-send "Configuring PRIMARY monitor $monitor with geometry $monitor_geometry"
            bspc monitor $monitor_name \
                --rectangle "$monitor_geometry" \
                --reset-desktops Shell WWW Code Chat ♫ y z t
            ;;
        (*)
            notify-send "Configuring SECONDARY monitor $monitor with geometry $monitor_geometry"
            bspc monitor $monitor_name \
                --rectangle "$monitor_geometry" \
                --reset-desktops Aux
            ;;
    esac
done

bspc wm --adopt-orphans
