#!/bin/bash

echo "󰘚 $(lspci | grep -i 'vga\|3d\|display' | grep -i intel | sed 's/.*: //')"
