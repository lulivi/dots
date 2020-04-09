#!/usr/bin/env bash
# Copyright (c) 2018 Luis Liñán <luislivilla at gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# This script uses i3lock to lock screen with a pixelized screenshot
# 
# Dependencies: scrot, imagemagick, i3lock

playerctl pause &>/dev/null

# Obtain the screen resolution with xdpyinfo
res=""$(xdpyinfo | awk '/dimensions:/ {print $2}')"!"

# Compute default sample value
sample="$((${res%%x*} / 8))"

# Capture screenshot
/usr/bin/scrot -o "/tmp/screenshot.png"

# Pixelizeit with imagemagik script
/usr/bin/convert "/tmp/screenshot.png" \
    -sample "${1:-$sample}" \
    -scale "$res" \
    "/tmp/screenshotblur.png"

# Lock screen with the pixelized image
/usr/bin/i3lock -e -i "/tmp/screenshotblur.png"
