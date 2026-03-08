#!/bin/bash

OWN_COUNTRY="CN"

CURRENT_COUNTRY=$(curl -s https://api.ipinfo.io/lite/me\?token\="$(cat ~/.ipinfo_token.txt)" | jq -r ".country_code")

if [ "$CURRENT_COUNTRY" != "$OWN_COUNTRY" ]; then
    $HOME/.local/bin/tsoff
    notify-send "ts Exit-Node OFF"
else
    $HOME/.local/bin/tson
    notify-send "ts Exit-Node ON"
fi

