#!/usr/bin/env bash
# 启动/重启 waybar（只用于 sway）。
# - 顶栏：bars/sway_top_bar.jsonc
# - 电池下拉小栏：bars/bat_bar.jsonc（start_hidden，点顶栏电池才显示）
# - 先清掉旧实例，避免 reload / 手动重启后出现重复的状态栏

set -u

configs=(
  "$HOME/.config/waybar/bars/sway_top_bar.jsonc"
  "$HOME/.config/waybar/bars/bat_bar.jsonc"
)

# 只杀 waybar 本体，不碰本脚本
pkill -x waybar 2>/dev/null
for _ in $(seq 1 20); do
  pgrep -x waybar >/dev/null 2>&1 || break
  sleep 0.05
done
pkill -9 -x waybar 2>/dev/null || true

for cfg in "${configs[@]}"; do
  [ -f "$cfg" ] || continue
  waybar -c "$cfg" >/dev/null 2>&1 &
done
