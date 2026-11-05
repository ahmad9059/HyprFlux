#!/bin/bash
# Select cyan variants already shipped in the signed Papirus package.
# Called as root by module 04 and after Papirus upgrades; no AUR required.
set -euo pipefail
theme="${1:-/usr/share/icons/Papirus}"
count=0
for size in 22x22 24x24 32x32 48x48 64x64; do
    for icon in "$theme/$size/places/"{folder,user}-cyan*.svg; do
        [[ -f "$icon" && ! -L "$icon" ]] || continue
        name="${icon##*/}"
        link="${name/-cyan/}"
        [[ "$link" != "$name" ]] || exit 1
        ln -sfn -- "$name" "${icon%/*}/$link"
        count=$((count + 1))
    done
done
(( count > 0 )) || { echo 'ERROR: Papirus cyan variants are missing.' >&2; exit 1; }
for size in 22x22 24x24 32x32 48x48 64x64; do
    [[ $(readlink -f "$theme/$size/places/folder.svg") == */folder-cyan.svg ]] || exit 1
done
if command -v gtk-update-icon-cache >/dev/null; then
    for sibling in Papirus Papirus-Dark Papirus-Light; do
        [[ -f "${theme%/*}/$sibling/index.theme" ]] || continue
        gtk-update-icon-cache -qf "${theme%/*}/$sibling"
    done
fi
echo "Papirus cyan folders verified ($count variants)."
