#!/bin/bash

DEST_DIR=$HOME/Pictures/WallPapers
mkdir -p "$DEST_DIR"

URLS=(
    "https://w.wallhaven.cc/full/je/wallhaven-jexkwm.jpg"
    "https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/1080p/Monterey-morning.jpg"
    "https://w.wallhaven.cc/full/d8/wallhaven-d8p83m.jpg"
    "https://w.wallhaven.cc/full/57/wallhaven-57pjl8.jpg"
    "https://w.wallhaven.cc/full/k8/wallhaven-k88ozm.jpg"
    "https://w.wallhaven.cc/full/nr/wallhaven-nryz17.jpg"
    "https://w.wallhaven.cc/full/xe/wallhaven-xe82x3.jpg"
    "https://w.wallhaven.cc/full/3z/wallhaven-3z97yd.jpg"
)

for url in "${URLS[@]}";do
    filename=$(basename "$url")
    if [ ! -f "$DEST_DIR/$filename" ];then
        wget -nc -P "$DEST_DIR" "$url"
    fi
done
