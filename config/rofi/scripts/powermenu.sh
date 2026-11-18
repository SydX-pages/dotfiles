#!/usr/bin/env bash
# rofi 电源菜单（替代 wlogout）
# 键位：$mod+0 仍然保留 sway 自带的 system 模式；这个菜单主要给 waybar 的电源按钮用。

set -u

lock_cmd=(swaylock -f -i /home/sydx/Pictures/WallPapers/IMG_3534.PNG)

entries=$(
  printf '%s\n' \
    "󰌾  锁定" \
    "󰒲  挂起" \
    "󰍃  注销" \
    "󰑓  重启" \
    "󰐥  关机"
)

chosen=$(printf '%s\n' "$entries" | rofi -dmenu -i -p "电源" -lines 5 \
  -theme "$HOME/.config/rofi/powermenu.rasi")

case "$chosen" in
  *锁定) exec "${lock_cmd[@]}" ;;
  *挂起) exec systemctl suspend ;;
  *注销) exec swaymsg exit ;;
  *重启) exec systemctl reboot ;;
  *关机) exec systemctl poweroff ;;
esac
