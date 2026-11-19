#!/usr/bin/env bash
# 天气模块：wttr.in -> waybar JSON
# 本机没有 wttrbar，所以用 curl + jq 自己做一个轻量版，带 30 分钟缓存。
# 输出示例：{"text":"󰖙 8°C","tooltip":"...","class":"sunny"}

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
CACHE="$CACHE_DIR/weather.json"
TTL=1800

mkdir -p "$CACHE_DIR"

need_fetch=1
if [ -s "$CACHE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
    [ "$age" -lt "$TTL" ] && need_fetch=0
fi

if [ "$need_fetch" -eq 1 ]; then
    tmp=$(mktemp "$CACHE.XXXXXX")
    if curl -fsS --max-time 8 'https://wttr.in/?format=j1' -o "$tmp" 2>/dev/null \
        && jq -e '.current_condition[0]' "$tmp" >/dev/null 2>&1; then
        mv "$tmp" "$CACHE"
    else
        rm -f "$tmp"
    fi
fi

if [ ! -s "$CACHE" ]; then
    jq -cn '{text: "—", tooltip: "Weather unavailable (no network?)", class: "offline"}'
    exit 0
fi

# 用 Tab 分隔读取，避免 weatherDesc 里的空格把字段拆错
IFS=$'\t' read -r temp feels code humidity wind < <(
    jq -r '.current_condition[0] | [.temp_C, .FeelsLikeC, .weatherCode, .humidity, .windspeedKmph] | @tsv' "$CACHE"
)
desc=$(jq -r '.current_condition[0].weatherDesc[0].value // ""' "$CACHE" | sed 's/[[:space:]]*$//')
city=$(jq -r '.nearest_area[0].areaName[0].value // "Unknown location"' "$CACHE")

case "$code" in
    113) icon="󰖙"; class="sunny" ;;
    116) icon="󰖕"; class="cloudy" ;;
    119|122) icon="󰖐"; class="cloudy" ;;
    143|149|248|260) icon="󰼰"; class="mist" ;;
    200|386|389|392) icon="󰖓"; class="storm" ;;
    227|230|329|332|335|338|368|371) icon="󰖘"; class="snow" ;;
    176|179|182|185|281|284|293|296|299|302|305|308|311|314|317|320|323|326|350|353|356|359|362|365|374|377|395)
        icon="󰖗"; class="rain" ;;
    *) icon="󰖑"; class="mist" ;;
esac

text="$icon ${temp}°C"
tooltip=$(printf '%s · %s\nFeels like %s°C\nHumidity %s%% · Wind %s km/h\n\nLeft-click: open wttr.in' \
    "$city" "$desc" "$feels" "$humidity" "$wind")

jq -cn \
    --arg text "$text" \
    --arg tooltip "$tooltip" \
    --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class}'
