#!/usr/bin/env bash
# rofi 电源菜单（替代 wlogout）
# 键位：$mod+0 仍然保留 sway 自带的 system 模式；这个菜单主要给 waybar 的电源按钮用。

set -u

lock_cmd=(swaylock -f -i /home/sydx/Pictures/WallPapers/IMG_3534.PNG)

entries=$(
    printf '%s\n' \
        "󰌾  Lock" \
        "󰒲  Suspend" \
        "󰍃  Logout" \
        "󰑓  Reboot" \
        "󰐥  Shutdown"
)

chosen=$(printf '%s\n' "$entries" | rofi -dmenu -i -p "PowerMenu" -lines 5 \
    -theme "$HOME/.config/rofi/powermenu.rasi")

case "$chosen" in
    *Lock) exec "${lock_cmd[@]}" ;;
    *Suspend) exec systemctl suspend ;;
    *Logout) exec swaymsg exit ;;
    *Reboot) exec systemctl reboot ;;
    *Shutdown) exec systemctl poweroff ;;
esac
