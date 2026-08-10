#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Game Mode toggle — disables animations/blur/shadows/rounding/gaps and forces
# full opacity for gaming. Toggling off restores the EXACT previous values
# (saved to $XDG_RUNTIME_DIR/gamemode.state), so manual tweaks (ChangeBlur,
# ChangeLayout, etc.) are preserved.

notif="dialog-information"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
STATE_FILE="$XDG_RUNTIME_DIR/gamemode.state"

# Read a single-value option (line 1, field 2; css gaps use the top value)
getopt() {
    hyprctl getoption "$1" | awk 'NR==1{print $2}'
}
getgaps() {  # css gap data: T R B L -> top value
    hyprctl getoption "$1" | awk 'NR==1{print $4}'
}

enable_gamemode() {
    # save the current state so it can be restored exactly
    {
        echo "gaps_in=$(getgaps general:gaps_in)"
        echo "gaps_out=$(getgaps general:gaps_out)"
        echo "border_size=$(getopt general:border_size)"
        echo "rounding=$(getopt decoration:rounding)"
        echo "blur_enabled=$(getopt decoration:blur:enabled)"
        echo "shadow_enabled=$(getopt decoration:shadow:enabled)"
        echo "animations_enabled=$(getopt animations:enabled)"
        echo "active_opacity=$(getopt decoration:active_opacity)"
        echo "inactive_opacity=$(getopt decoration:inactive_opacity)"
    } > "$STATE_FILE"

    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0,
                       active_opacity = 1.0, inactive_opacity = 1.0 },
        general = { gaps_in = 0, gaps_out = 0, border_size = 0 }
    })'
    awww kill
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
}

disable_gamemode() {
    # default values (used if the state file is missing)
    local gaps_in=2 gaps_out=4 border_size=2 rounding=10
    local blur_enabled=true shadow_enabled=false animations_enabled=true
    local active_opacity=1.0 inactive_opacity=0.9

    if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
    fi

    hyprctl eval "hl.config({
        animations = { enabled = $animations_enabled },
        decoration = { shadow = { enabled = $shadow_enabled }, blur = { enabled = $blur_enabled },
                       rounding = $rounding, active_opacity = $active_opacity,
                       inactive_opacity = $inactive_opacity },
        general = { gaps_in = $gaps_in, gaps_out = $gaps_out, border_size = $border_size }
    })"

    awww-daemon --format xrgb && awww img "$HOME/.config/rofi/.current_wallpaper" &
    sleep 0.1
    ${SCRIPTSDIR}/WallpaperAwww.sh
    sleep 0.5
    ${SCRIPTSDIR}/Refresh.sh
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
}

if [ -f "$STATE_FILE" ]; then
    disable_gamemode
    rm -f "$STATE_FILE"
else
    enable_gamemode
fi
