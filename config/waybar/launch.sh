#!/bin/bash

waybar -c ~/.config/waybar/bars/top_bar.jsonc &
waybar -c ~/.config/waybar/bars/dock_bar.jsonc &
waybar -c ~/.config/waybar/bars/widgets_bar.jsonc &
waybar -c ~/.config/waybar/bars/net_bar.jsonc &
waybar -c ~/.config/waybar/bars/bat_bar.jsonc &
