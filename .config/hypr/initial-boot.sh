#!/bin/bash
# Installer modules own GTK/Kvantum/cursor defaults; do not overwrite them here.
# StartupWallpapers.sh owns wallpaper restoration on every session start.
set -euo pipefail
config="$(dirname -- "${BASH_SOURCE[0]}")"
if [[ ! -e "$config/.initial_startup_done" ]]; then
    touch "$config/.initial_startup_done"
fi
