#!/bin/bash

if [ ! -d "$HOME/.oh-my-zsh" ];then
    sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --keep-zshrc --unattended
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

install_plugin(){
    local plugin_url=$1
    local plugin_name=$(basename "$plugin_url")
    local plugin_dir="$ZSH_CUSTOM/plugins/$plugin_name"

    if [ ! -d "$plugin_dir" ];then
        git clone --depth 1 "$plugin_url" "$plugin_dir"
    fi
}

install_plugin "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting"
install_plugin "https://github.com/zsh-users/zsh-history-substring-search"

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi
