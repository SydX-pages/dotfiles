#!/bin/zsh

for file in $PWD/config/*; do
    ln -s "$file" "$HOME/.config/"
done

for file in $PWD/Custom/Apps/*; do
    ln -s "$file" "$HOME/Custom/Apps/"
done

for file in $PWD/home/*; do
    base="$(basename $file)"
    ln -s "$file" "$HOME/.$base"
done

for file in $PWD/local/*; do
    ln -s "$file" "$HOME/.local/"
done

ln -s "$PWD/pngs/WallPapers" "$HOME/Pictures/WallPapers"

for file in $PWD/local/*; do
    ln -s "$file" "$HOME/.local/"
done
