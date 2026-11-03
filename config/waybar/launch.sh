#!/bin/bash

# sway 下用 bars/sway_top_bar.jsonc（sway/* 模块），其它桌面用 bars/top_bar.jsonc
if [ -n "$SWAYSOCK" ]; then
  top_bar="$HOME/.config/waybar/bars/sway_top_bar.jsonc"
else
  top_bar="$HOME/.config/waybar/bars/top_bar.jsonc"
fi

waybar -c "$top_bar" &
waybar -c ~/.config/waybar/bars/dock_bar.jsonc &
waybar -c ~/.config/waybar/bars/widgets_bar.jsonc &
waybar -c ~/.config/waybar/bars/net_bar.jsonc &
waybar -c ~/.config/waybar/bars/bat_bar.jsonc &
