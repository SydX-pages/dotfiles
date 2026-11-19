#!/usr/bin/env bash
# 网络上下行速度（waybar custom module）
# 读取 /proc/net/dev，与上一次采样比较；采样状态存到 cache。
# 输出示例：{"text":"↓1.2M ↑256K","tooltip":"..."}

set -u

STATE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/netspeed.state"
mkdir -p "$(dirname "$STATE")"

now=$(date +%s%N)

# 汇总所有非回环 / 非虚拟网卡的 rx、tx 字节数
read -r rx tx ifaces < <(awk '
  NR > 2 {
    iface = $0
    sub(/:.*/, "", iface)
    gsub(/^[ \t]+|[ \t]+$/, "", iface)
    if (iface ~ /^(lo|veth|docker|br-|virbr|tun|tap|tailscale|wg)/) next

    stats = $0
    sub(/^[^:]*:/, "", stats)
    sub(/^[ \t]+/, "", stats)
    split(stats, f, /[ \t]+/)

    rx += f[1]
    tx += f[9]
    names = (names == "" ? iface : names "," iface)
  }
  END { printf "%d %d %s\n", rx, tx, (names == "" ? "-" : names) }
' /proc/net/dev)

# 上一次采样；文件损坏时直接以当前值作为基准
prx=$rx
ptx=$tx
ptime=$now
if [ -s "$STATE" ]; then
  read -r prx ptx ptime < "$STATE" 2>/dev/null || true
  case "${prx:-x}:${ptx:-x}:${ptime:-x}" in
    *[!0-9:]*) prx=$rx; ptx=$tx; ptime=$now ;;
  esac
fi

printf '%s %s %s\n' "$rx" "$tx" "$now" > "$STATE"

dt_ms=$(( (now - ptime) / 1000000 ))
[ "$dt_ms" -le 0 ] && dt_ms=1000

d_rx=$(( rx - prx ))
d_tx=$(( tx - ptx ))
[ "$d_rx" -lt 0 ] && d_rx=0
[ "$d_tx" -lt 0 ] && d_tx=0

down=$(( d_rx * 1000 / dt_ms ))
up=$(( d_tx * 1000 / dt_ms ))

# 字节/秒 -> 人类可读
rate() {
  local b=$1
  if [ "$b" -ge 1048576 ]; then
    printf '%d.%dM' $(( b / 1048576 )) $(( (b % 1048576) * 10 / 1048576 ))
  elif [ "$b" -ge 1024 ]; then
    printf '%dK' $(( b / 1024 ))
  else
    printf '%dB' "$b"
  fi
}

text="↓$(rate "$down") ↑$(rate "$up")"
tooltip=$(printf 'Down: %s/s\nUp: %s/s\nInterface: %s' \
  "$(rate "$down")" "$(rate "$up")" "$ifaces")

jq -cn --arg text "$text" --arg tooltip "$tooltip" \
  '{text: $text, tooltip: $tooltip}'
