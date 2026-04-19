#!/bin/bash

policy=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

if [ "$policy" = "powersave" ]; then
    echo "󰂄 Powersave"
else
    echo " Performance"
fi

