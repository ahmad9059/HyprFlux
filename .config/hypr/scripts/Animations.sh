#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# For applying Animations from different users
# (Hyprland >= 0.55: presets are Lua modules; a config reload applies them)

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

# Variables
SCRIPTSDIR="$HOME/.config/hypr/scripts"
animations_dir="$HOME/.config/hypr/animations"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
msg='❗NOTE:❗ This will copy animations into user-animations.lua'
# list of animation files, sorted alphabetically with numbers first
animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f -name '*.lua' | sed 's/.*\///' | sed 's/\.lua$//' | sort -V)

# Rofi Menu
chosen_file=$(echo "$animations_list" | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

# Check if a file was selected
if [[ -n "$chosen_file" ]]; then
  full_path="$animations_dir/$chosen_file.lua"
  cp "$full_path" "$UserConfigs/user-animations.lua"
  # reload the Lua config so the new animations module applies
  hyprctl reload
  notify-send -u low -i "dialog-information" "$chosen_file" "Hyprland Animation Loaded"
fi

sleep 1
"$SCRIPTSDIR/RefreshNoWaybar.sh"
