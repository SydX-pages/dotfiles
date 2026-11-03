#!/bin/sh
# 屏幕键盘开关：show / hide / toggle（默认 toggle）
# 用法：osk.sh [show|hide|toggle]

NAME=wvkbd-mobintl
HEIGHT=420
LANDSCAPE_HEIGHT=260
FONT="JetBrains Mono Nerd Font 20"

if ! pgrep -x "$NAME" >/dev/null 2>&1; then
    setsid "$NAME" -H "$HEIGHT" -L "$LANDSCAPE_HEIGHT" --fn "$FONT" --hidden \
        >/dev/null 2>&1 &
    sleep 0.3
fi

case "${1:-toggle}" in
    show)   pkill -USR2 -x "$NAME" ;;
    hide)   pkill -USR1 -x "$NAME" ;;
    toggle) pkill -SIGRTMIN -x "$NAME" ;;
    *)
        printf 'usage: %s [show|hide|toggle]\n' "$0" >&2
        exit 2
        ;;
esac
