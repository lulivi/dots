#!/usr/bin/env sh

pkill kanshi
sleep 3
echo -e "\n>>>>>>>>>>>>>>>>>>>>>>>\n$(date)" >> /tmp/kanshi.log
kanshi >> /tmp/kanshi.log 2>&1
