#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# For Searching via web browsers

# Define the path to the config file (Lua defaults module, Hyprland >= 0.55)
config_file=$HOME/.config/hypr/UserConfigs/user-defaults.lua

# Check if the config file exists
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration file not found!"
    exit 1
fi

# Extract the search engine URL from the Lua module
Search_Engine=$(grep 'search_engine' "$config_file" | head -1 | sed 's/.*search_engine = "\([^"]*\)".*/\1/')

# Check if Search_Engine is set correctly
if [[ -z "$Search_Engine" ]]; then
    echo "Error: search_engine is not set in the configuration file!"
    exit 1
fi

# Rofi theme and message
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='‼️ **note** ‼️ search via default web browser'

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# Open Rofi and pass the selected query to xdg-open for Google search
echo "" | rofi -dmenu -config "$rofi_theme" -mesg "$msg" | xargs -I{} xdg-open $Search_Engine