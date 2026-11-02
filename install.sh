#!/bin/zsh

./scripts/link.sh
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
