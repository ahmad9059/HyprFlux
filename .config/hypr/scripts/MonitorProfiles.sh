#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# For applying Pre-configured Monitor Profiles
#
# Hyprland >= 0.55: profiles are stored as .lua (used by hyprland.lua).
# Legacy .conf profiles are still applied when they exist (kept until the
# entrypoint flip). The profile list prefers .lua, falls back to .conf.

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Variables
iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
monitor_dir="$HOME/.config/hypr/Monitor_Profiles"
target_conf="$HOME/.config/hypr/monitors.conf"
target_lua="$HOME/.config/hypr/monitors.lua"
rofi_theme="$HOME/.config/rofi/config-Monitors.rasi"
msg='❗NOTE:❗ This will overwrite monitors.conf / monitors.lua'

# Define the list of files to ignore
ignore_files=(
  "README"
)

# list of Monitor Profiles, sorted alphabetically with numbers first
# (prefer .lua profiles; fall back to .conf)
mon_profiles_list=$(find -L "$monitor_dir" -maxdepth 1 -type f \( -name '*.lua' -o -name '*.conf' \) | \
  sed 's/.*\///' | sed -E 's/\.(lua|conf)$//' | sort -u -V)

# Remove ignored files from the list
for ignored_file in "${ignore_files[@]}"; do
    mon_profiles_list=$(echo "$mon_profiles_list" | grep -v -E "^$ignored_file$")
done

# Rofi Menu
chosen_file=$(echo "$mon_profiles_list" | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

if [[ -n "$chosen_file" ]]; then
    if [[ -f "$monitor_dir/$chosen_file.lua" ]]; then
        cp "$monitor_dir/$chosen_file.lua" "$target_lua"
        # keep .conf in sync so legacy boots still work until the flip
        if [[ -f "$monitor_dir/$chosen_file.conf" ]]; then
            cp "$monitor_dir/$chosen_file.conf" "$target_conf"
        fi
    elif [[ -f "$monitor_dir/$chosen_file.conf" ]]; then
        # legacy .conf-only profile: warn that it cannot apply to the Lua session
        notify-send -u normal -i "$iDIR/error.png" "$chosen_file" "Legacy .conf profile — create a .lua profile (nwg-displays) for it to apply"
        cp "$monitor_dir/$chosen_file.conf" "$target_conf"
    fi

    notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
${SCRIPTSDIR}/RefreshNoWaybar.sh &
