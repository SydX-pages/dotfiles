#!/bin/bash

echo "󰘚  $(lspci | grep -i vga | grep -i nvidia | awk -F: '{print $3}')"
