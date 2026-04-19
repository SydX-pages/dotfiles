#!/bin/bash

if bluetoothctl show | grep -q "Powered: yes";then
    if bluetoothctl info | grep -q Name;then
        name=$(echo "$(bluetoothctl info | grep Name)" | cut -d ':' -f2 | xargs)
        echo "󰂱$name"
    else
        echo "󰂯on"
    fi
else
    echo "󰂲off";
fi
