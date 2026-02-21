#!/usr/bin/env sh

# 8888888b.  888     888 888      8888888888 .d8888b.
# 888   Y88b 888     888 888      888       d88P  Y88b
# 888    888 888     888 888      888       Y88b.
# 888   d88P 888     888 888      8888888    "Y888b.
# 8888888P"  888     888 888      888           "Y88b.
# 888 T88b   888     888 888      888             "888
# 888  T88b  Y88b. .d88P 888      888       Y88b  d88P
# 888   T88b  "Y88888P"  88888888 8888888888 "Y8888P"

# Clean old rules
for rule in $(bspc rule --list | cut -d'=' -f1); do
    bspc rule --remove $rule
done

bspc rule --add Chromium desktop='^1'
bspc rule --add librewolf-default desktop='^2'

# bspc rule --add Code desktop='^3'

bspc rule --add TelegramDesktop desktop='^4'
bspc rule --add Slack state=tiled desktop='^4'

bspc rule --add Spotify state=tiled desktop='^5'

bspc rule --add brave-browser state=tiled desktop='^6'
