#!/usr/bin/env sh

pkill kanshi
sleep 3
cat << EOF >> /tmp/kanshi.log

>>>>>>>>>>>>>>>>>>>>>>>
$(date)
>>>>>>>>>>>>>>>>>>>>>>>
EOF
kanshi >> /tmp/kanshi.log 2>&1
