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
# Dependencies: maim, imagemagick, i3lock

playerctl pause &>/dev/null

lock_screen_image="$1"

_f() {
    if [ -f "$lock_screen_image" ]; then return; fi

    # Take a screenshot if no file is provided
    lock_screen_image="/tmp/screenshotblur.png"
    local screenshot_image="/tmp/screenshot"
    maim "$screenshot_image"

    # Obtain the screen resolution with xdpyinfo and compute the sample value
    res=""$(xdpyinfo | awk '/dimensions:/ {print $2}')"!"
    sample="$((${res%%x*} / 8))"

    # Pixelize the screenshot with imagemagik script
    /usr/bin/convert \
        $screenshot_image \
        -sample "$sample" \
        -scale "$res" \
        "$lock_screen_image"
}; _f

# Lock screen
/usr/bin/i3lock -e -p default -i "$lock_screen_image"
