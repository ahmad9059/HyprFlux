#!/bin/bash
# PulseAudio/PipeWire control: only announce operations that actually succeeded.
set -euo pipefail
scripts="$(dirname -- "${BASH_SOURCE[0]}")"

icon() {
    local volume
    if [[ "$(pamixer --get-mute)" == true ]]; then
        echo audio-volume-muted
        return
    fi
    volume=$(pamixer --get-volume)
    if (( volume <= 30 )); then echo audio-volume-low
    elif (( volume <= 60 )); then echo audio-volume-medium
    else echo audio-volume-high; fi
}

report() {
    local kind="$1" volume muted label image
    if [[ "$kind" == mic ]]; then
        volume=$(pamixer --default-source --get-volume)
        muted=$(pamixer --default-source --get-mute)
        label=Microphone
        image=audio-input-microphone
    else
        volume=$(pamixer --get-volume)
        muted=$(pamixer --get-mute)
        label=Volume
        image=$(icon)
    fi
    [[ "$volume" =~ ^[0-9]+$ ]] || { echo 'Invalid volume response' >&2; return 1; }
    if [[ "$muted" == true ]]; then label+=" (muted)"; fi
    notify-send -e -u low -h string:x-canonical-private-synchronous:volume_notif \
        -h "int:value:$volume" -i "$image" "$label" "$volume%" || true
}

case "${1:---get}" in
    --get) if [[ "$(pamixer --get-mute)" == true ]]; then echo Muted; else printf '%s %%\n' "$(pamixer --get-volume)"; fi ;;
    --get-icon) icon ;;
    --get-mic-icon)
        if [[ "$(pamixer --default-source --get-mute)" == true ]]; then echo audio-input-microphone-muted
        else echo audio-input-microphone; fi ;;
    --inc|--dec)
        pamixer -u
        if [[ "$1" == --inc ]]; then pamixer -i 5 --allow-boost --set-limit 150
        else pamixer -d 5; fi
        report volume
        bash "$scripts/Sounds.sh" --volume || true ;;
    --toggle) pamixer --toggle-mute; report volume ;;
    --toggle-mic) pamixer --default-source --toggle-mute; report mic ;;
    --mic-inc|--mic-dec)
        pamixer --default-source -u
        if [[ "$1" == --mic-inc ]]; then pamixer --default-source -i 5
        else pamixer --default-source -d 5; fi
        report mic ;;
    *) echo 'Usage: Volume.sh --get|--get-icon|--inc|--dec|--toggle|--toggle-mic|--mic-inc|--mic-dec|--get-mic-icon' >&2; exit 2 ;;
esac
