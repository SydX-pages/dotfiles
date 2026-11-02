#!/bin/bash


SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"

for file in "$ROOT"/config/*; do
    [ -e "$file" ] || continue
    ln -sfn "$file" "$HOME/.config/"
done

for file in "$ROOT"/home/*; do
    [ -e "$file" ] || continue
    ln -sfn "$file" "$HOME/.$(basename "$file")"
done

for dir in "$ROOT"/local/*; do
    [ -d "$dir" ] || continue
    dest="$HOME/.local/$(basename "$dir")"
    mkdir -p "$dest"
    for file in "$dir"/*; do
        [ -e "$file" ] || continue
        ln -sfn "$file" "$dest/"
    done
done
