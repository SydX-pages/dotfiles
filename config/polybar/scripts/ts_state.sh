#!/bin/bash

OWN_COUNTRY="CN"
CURRENT_COUNTRY=$(curl -s https://api.ipinfo.io/lite/me\?token\="$(cat ~/.ipinfo_token.txt)" | jq -r ".country_code")


if [ "$CURRENT_COUNTRY" != "$OWN_COUNTRY" ]; then
    echo "VPN %{F#30D158} %{F-}"
else
    echo "VPN %{F#FF453A} %{F-}"
fi

