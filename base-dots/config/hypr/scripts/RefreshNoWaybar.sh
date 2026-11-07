#!/bin/bash
# No global Rofi/process kills; video wallpapers need no image-preview refresh.
set -euo pipefail
scripts="$(dirname -- "${BASH_SOURCE[0]}")"
if awww query >/dev/null 2>&1; then
    bash "$scripts/WallpaperAwww.sh"
fi
if pgrep -u "$UID" -x swaync >/dev/null; then
    swaync-client --reload-config
    swaync-client --reload-css
fi
