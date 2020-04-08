#!/usr/bin/env bash

if [ -z "$BOT_TOKEN" ]; then
    printf 'Please set $BOT_TOKEN variable.\n'
    exit 1
fi

if [ -z "$CHAT_ID" ]; then
    printf 'Please set $CHAT_ID variable.\n'
    exit 1
fi

if [ -z "$RC" ]; then
    printf 'Please set $RC variable.\n'
    exit 1
fi

URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
DATA="chat_id=${CHAT_ID}&text=Finished process with return code = ${RC}" 

obtained_json="$(curl -s --data "$DATA" $URL)"
petition_ok="$(printf '%s' "$obtained_json" | jq .ok)"

if [ "$petition_ok" == "false" ]; then
    printf 'There was an error: '
    printf '%s' "$obtained_json" | jq
    printf '\nPetition parementers:\n%s\n' "$DATA"
    exit 1
fi

exit 0

{"ok":true,"result":{"message_id":541}}