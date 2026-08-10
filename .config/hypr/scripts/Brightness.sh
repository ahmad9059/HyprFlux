#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Script for Monitor backlights (if supported) using brightnessctl
#
# NOTE: if the screen still drops at 100%, re-check that the kernel is not
# double-handling the Fn keys:
#   cat /sys/module/video/parameters/brightness_switch_enabled   (want: N)

notification_timeout=1000
step=10    # INCREASE/DECREASE BY THIS VALUE
MIN=5      # lowest allowed percent
MAX=95     # highest allowed percent

# Get current brightness as an integer (without %)
get_brightness() {
    local pct cur max
    pct=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
    if [[ -z "$pct" || ! "$pct" =~ ^[0-9]+$ ]]; then
        # fallback: compute the percentage from raw values
        cur=$(brightnessctl get 2>/dev/null)
        max=$(brightnessctl max 2>/dev/null)
        if [[ "$max" =~ ^[0-9]+$ && "$max" -gt 0 && "$cur" =~ ^[0-9]+$ ]]; then
            pct=$((cur * 100 / max))
        else
            pct=50
        fi
    fi
    echo "$pct"
}

# Determine the icon based on brightness level
get_icon_path() {
    echo "display-brightness"
}

# Send notification
send_notification() {
    local brightness=$1
    local icon_path=$2

    notify-send -e \
        -h string:x-canonical-private-synchronous:brightness_notif \
        -h int:value:"$brightness" \
        -u low \
        -i "$icon_path" \
        "Screen" "Brightness: ${brightness}%"
}

# Change brightness and notify
change_brightness() {
    local delta=$1
    local current new icon

    current=$(get_brightness)
    new=$((current + delta))

    # Clamp between MIN and MAX
    (( new < MIN )) && new=$MIN
    (( new > MAX )) && new=$MAX

    brightnessctl set "${new}%"

    icon=$(get_icon_path "$new")
    send_notification "$new" "$icon"
}

# Main
case "$1" in
    "--get")
        get_brightness
        ;;
    "--inc")
        change_brightness "$step"
        ;;
    "--dec")
        change_brightness "-$step"
        ;;
    *)
        get_brightness
        ;;
esac
