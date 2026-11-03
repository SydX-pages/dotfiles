#!/bin/sh
# 切换触摸板开关（Wayland/sway 下用 input events toggle）
# 原配置里的 `swaymsg input "$id" toggle enable` 语法是错的，已经改成这个脚本。

id=$(swaymsg -t get_inputs -r | jq -r '.[] | select(.type == "touchpad") | .identifier' | head -n1)
[ -n "$id" ] || exit 1

swaymsg input "$id" events toggle enabled disabled >/dev/null
notify-send "Touchpad toggled"
