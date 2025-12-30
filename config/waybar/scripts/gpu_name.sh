#!/bin/bash

echo "󰘚 $(lspci | grep -i vga | awk -F: '{print $3}')"

