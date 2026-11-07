#!/bin/bash
# Best-effort themed sounds, with a valid PulseAudio fallback.
set -euo pipefail
[[ "${HYPRFLUX_MUTE_SOUNDS:-false}" == true ]] && exit 0
case "${1:-}" in
    --screenshot) sound=screen-capture ;;
    --volume) sound=audio-volume-change ;;
    --error) sound=dialog-error ;;
    *) echo 'Usage: Sounds.sh --screenshot|--volume|--error' >&2; exit 2 ;;
esac
system=/usr/share/sounds
[[ -d /run/current-system/sw/share/sounds ]] && system=/run/current-system/sw/share/sounds
user="${XDG_DATA_HOME:-$HOME/.local/share}/sounds"
theme="${HYPRFLUX_SOUND_THEME:-freedesktop}"
directories=("$user/$theme" "$system/$theme")
for directory in "${directories[@]}"; do
    if [[ -r "$directory/index.theme" ]]; then
        inherited=$(sed -n 's/^[Ii]nherits=//p' "$directory/index.theme" | head -n 1)
        IFS=, read -r -a inherited_themes <<< "$inherited"
        for parent in "${inherited_themes[@]}"; do
            [[ -n "$parent" ]] && directories+=("$user/$parent" "$system/$parent")
        done
    fi
done
directories+=("$user/freedesktop" "$system/freedesktop")
file=
for directory in "${directories[@]}"; do
    [[ -d "$directory/stereo" ]] || continue
    file=$(find -L "$directory/stereo" -type f -name "$sound.*" -print -quit)
    [[ -n "$file" ]] && break
done
[[ -n "$file" ]] || { echo "Sound not found: $sound" >&2; exit 1; }
if command -v pw-play >/dev/null 2>&1 && pw-play "$file"; then
    exit 0
fi
exec paplay "$file"
