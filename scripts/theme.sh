#!/bin/bash

install_script(){
    local name=$1
    local dir=$2

    cd "$dir" || return

    case "$name" in
        "WhiteSur-icon-theme")
            ./install.sh -t pink
            ;;
        "WhiteSur-gtk-theme")
            ./install.sh -l -t pink -N glassy
            ./tweaks.sh -F -c Dark -t pink
            ;;
        *)
            echo "没有这个主题"
            ;;
    esac

    cd .. && rm -rf "$dir"
}

install_resource() {
    local url=$1

    local dir="$HOME/.cache/$(basename "$url")"

    if [ ! -d "$dir" ]; then
        git clone --depth 1 "$url" "$dir"
        install_script "$(basename "$url")" "$dir"
    fi
}

install_resource "https://github.com/vinceliuice/WhiteSur-gtk-theme"
install_resource "https://github.com/vinceliuice/WhiteSur-icon-theme"
