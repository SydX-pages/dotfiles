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

# from https://gist.github.com/patrickhaahr/75e36373e67c47d81b12593aab8c18e9
git clone https://gist.github.com/75e36373e67c47d81b12593aab8c18e9.git $HOME/.cache/capture-gif
cd $HOME/.cache/capture-gif/
mv ./* $HOME/.local/bin/capture-gif
chmod +x $HOME/.local/bin/capture-gif
rm $HOME/.cache/capture-gif/ -r
