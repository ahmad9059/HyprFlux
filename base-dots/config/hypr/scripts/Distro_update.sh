#!/bin/bash
# Run the entire transaction in one terminal and report its actual exit status.
set -euo pipefail
command -v kitty >/dev/null || { echo 'Kitty is required' >&2; exit 1; }
if command -v paru >/dev/null; then command=(paru -Syu)
elif command -v yay >/dev/null; then command=(yay -Syu)
elif command -v pacman >/dev/null; then command=(sudo pacman -Syu)
elif command -v dnf >/dev/null; then command=(sudo dnf upgrade --refresh)
elif command -v apt >/dev/null; then command=(sh -c 'sudo apt update && sudo apt upgrade')
elif command -v zypper >/dev/null; then command=(sudo zypper dup)
else echo 'Unsupported package manager' >&2; exit 1; fi
exec kitty --title update -e bash -c '
    "$@"
    result=$?
    if (( result == 0 )); then
        notify-send -u low "System update" "Completed successfully"
        python3 "$HOME/.config/hypr/scripts/WaybarStatus.py" refresh-updates || true
    else
        notify-send -u critical "System update failed" "Exit code: $result"
        read -r -p "Press Enter to close..." || true
    fi
    exit "$result"
' _ "${command[@]}"
