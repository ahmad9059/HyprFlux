#!/bin/bash
# Explicit user actions only; opening the panel runs read-only status commands.
set -euo pipefail

case "${1:-}" in
    lock) exec bash "$HOME/.config/hypr/scripts/LockScreen.sh" ;;
    power) exec bash "$HOME/.config/hypr/scripts/Wlogout.sh" ;;
    settings) exec bash "$HOME/.config/hypr/scripts/HyprFlux_Quick_Settings.sh" ;;
    network) exec bash "$HOME/.config/hypr/scripts/WaybarScripts.sh" --nmtui ;;
    status-output|status-input)
        source=()
        [[ "$1" == status-input ]] && source=(--default-source)
        state=$(pamixer "${source[@]}" --get-mute)
        [[ "$state" == true || "$state" == false ]] || { echo 'Invalid audio mute state' >&2; exit 1; }
        printf '%s\n' "$state" ;;
    mute-output|mute-input)
        source=()
        [[ "$1" == mute-input ]] && source=(--default-source)
        case "${SWAYNC_TOGGLE_STATE:-}" in
            true) exec pamixer "${source[@]}" --mute ;;
            false) exec pamixer "${source[@]}" --unmute ;;
            *) echo 'SwayNC toggle state must be true or false' >&2; exit 2 ;;
        esac ;;
    *) echo 'Usage: actions.sh lock|power|settings|network|mute-output|mute-input|status-output|status-input' >&2; exit 2 ;;
esac
