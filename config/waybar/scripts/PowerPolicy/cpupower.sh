#!/bin/bash

policy=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)

if [ "$policy" = "powersave" ]; then
    sudo cpupower frequency-set -g performance
else
    sudo cpupower frequency-set -g powersave
fi


