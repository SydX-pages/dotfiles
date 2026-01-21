#!/bin/bash

OWN_COUNTRY="CN"
CURRENT_COUNTRY=$(curl -s https://api.ipinfo.io/lite/me\?token\="$(cat ~/.ipinfo_token.txt)" | jq -r ".country_code")

if [ "$CURRENT_COUNTRY" != "$OWN_COUNTRY" ]; then
    ICON="🟢"  # Exit Node ON
    TIP="Click to Turn OFF"
else
    ICON="🔴"  # Exit Node OFF
    TIP="Click to Turn ON"
fi

printf '{"text":"%s","tooltip":"%s"}\n' "$ICON" "$TIP"
