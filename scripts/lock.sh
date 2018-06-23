#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>
# Dependences: scrot, imagemagick, i3lock

/usr/bin/scrot /tmp/screenshot.png
/usr/bin/convert /tmp/screenshot.png \
		 -sample 250 \
		 -scale 1920x1080! \
		 /tmp/screenshotblur.png
/usr/bin/i3lock -i /tmp/screenshotblur.png
