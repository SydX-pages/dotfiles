#!/usr/bin/env bash
# 给 waybar 用的通知计数（mako），输出 JSON。
# 左键恢复最近一条、右键全部清除；勿扰开关在单独的 custom/dnd 模块。

set -u

count=$(makoctl list 2>/dev/null | grep -c '^Notification')
count=${count:-0}

dnd=0
if makoctl mode 2>/dev/null | grep -qx 'do-not-disturb'; then
  dnd=1
fi

if [ "$count" -gt 0 ]; then
  if [ "$dnd" -eq 1 ]; then
    icon="󰂛"
    class="dnd"
  else
    icon="󰂚"
    class="has-notifications"
  fi
  text="$icon $count"
elif [ "$dnd" -eq 1 ]; then
  text="󰂛"
  class="dnd"
else
  text="󰂚"
  class="empty"
fi

if [ "$dnd" -eq 1 ]; then
  dnd_text="on"
else
  dnd_text="off"
fi

tooltip=$(printf 'Notifications: %s\nDND: %s\n\nLeft-click: restore latest\nRight-click: clear all\nDND: click the moon button' "$count" "$dnd_text")

jq -cn \
  --arg text "$text" \
  --arg class "$class" \
  --arg tooltip "$tooltip" \
  '{text: $text, class: $class, tooltip: $tooltip}'
