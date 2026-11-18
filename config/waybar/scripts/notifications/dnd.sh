#!/usr/bin/env bash
# 勿扰（do-not-disturb）开关按钮：输出 waybar JSON。
# 左键切换；关闭时显示灰色月亮，开启时显示橙色铃铛斜杠。

set -u

if makoctl mode 2>/dev/null | grep -qx 'do-not-disturb'; then
  icon="󰂛"
  class="on"
  state="on"
else
  icon="󰖔"
  class="off"
  state="off"
fi

tooltip=$(printf 'Do not disturb: %s\n\nLeft-click: toggle' "$state")

jq -cn \
  --arg text "$icon" \
  --arg class "$class" \
  --arg tooltip "$tooltip" \
  '{text: $text, class: $class, tooltip: $tooltip}'
