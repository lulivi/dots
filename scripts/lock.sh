#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>
# Dependences: scrot, imagemagick, i3lock

/usr/bin/scrot -o /tmp/screenshot.png
/usr/bin/convert /tmp/screenshot.png \
		 -sample 250 \
		 -scale $(xdpyinfo | grep dimensions | grep -Po "[0-9]+x[0-9]+(?= pixels)")! \
		 /tmp/screenshotblur.png
/usr/bin/i3lock -i /tmp/screenshotblur.png
