#!/bin/bash
# Keep one owner for hypridle. Manual legacy processes are stopped on migration.
set -euo pipefail
case "${1:-}" in
    status)
        if systemctl --user is-active --quiet hypridle.service || pgrep -u "$UID" -x hypridle >/dev/null; then
            printf '%s\n' '{"text":"RUNNING","class":"active","tooltip":"Automatic lock enabled. Click to pause; right-click to lock."}'
        else
            printf '%s\n' '{"text":"PAUSED","class":"notactive","tooltip":"Automatic lock is paused. Click to re-enable; right-click to lock."}'
        fi ;;
    toggle)
        if systemctl --user is-active --quiet hypridle.service; then
            systemctl --user stop hypridle.service
        elif pgrep -u "$UID" -x hypridle >/dev/null; then
            pkill -u "$UID" -x hypridle
        else
            systemctl --user start hypridle.service
            systemctl --user is-active --quiet hypridle.service
        fi ;;
    *) echo 'Usage: Hypridle.sh status|toggle' >&2; exit 2 ;;
esac
