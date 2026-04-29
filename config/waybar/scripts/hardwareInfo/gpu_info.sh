#!/bin/bash

used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)

echo "   ${used}MiB / ${total}MiB    ${temp}°C"
