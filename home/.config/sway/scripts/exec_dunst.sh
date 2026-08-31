#!/usr/bin/env sh

pkill dunst
dunst >/tmp/dunst.log 2>&1 &
