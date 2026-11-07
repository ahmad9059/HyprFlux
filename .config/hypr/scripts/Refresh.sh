#!/bin/bash
# Reload running components; do not race kill/restart or terminate other menus.
set -euo pipefail
if pgrep -u "$UID" -x waybar >/dev/null; then
    pkill -u "$UID" -USR2 -x waybar
else
    waybar >/dev/null 2>&1 &
fi
if pgrep -u "$UID" -x swaync >/dev/null; then
    swaync-client --reload-config
    swaync-client --reload-css
else
    swaync >/dev/null 2>&1 &
fi
