#!/bin/zsh

for file in $PWD/config/*; do
    ln -sf "$file" "$HOME/.config/"
done

for file in $PWD/home/*; do
    ln -sfn $file "$HOME/.$(basename $file)"
done

for dir in $PWD/local/*; do
    for file in "$dir"/*; do
        ln -sf "$file" "$HOME/.local/$(basename "$dir")/"
    done
done

./scripts/omz.sh
./scripts/theme.sh
./scripts/tmux.sh
./scripts/wallpaper.sh
