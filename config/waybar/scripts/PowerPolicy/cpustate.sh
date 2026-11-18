#!/bin/bash

policy=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

if [ "$policy" = "powersave" ]; then
    echo "󰂄 Save"
else
    echo " High"
fi

