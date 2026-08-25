#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# This file is used by waybar modules sourcing defaults set in
# $HOME/.config/hypr/UserConfigs/user-defaults.lua (Hyprland >= 0.55)

# Define the path to the config file
config_file=$HOME/.config/hypr/UserConfigs/user-defaults.lua

# Check if the config file exists
if [[ ! -f "$config_file" ]]; then
    echo "Error: Configuration file not found!"
    exit 1
fi

# Extract string values from the Lua defaults module
term=$(grep 'term = ' "$config_file" | head -1 | sed 's/.*term = "\([^"]*\)".*/\1/')
files=$(grep 'files = ' "$config_file" | head -1 | sed 's/.*files = "\([^"]*\)".*/\1/')

# Check if $term is set correctly
if [[ -z "$term" ]]; then
    echo "Error: term is not set in the configuration file!"
    exit 1
fi

# Execute accordingly based on the passed argument
if [[ "$1" == "--btop" ]]; then
    $term --title btop sh -c 'btop'
elif [[ "$1" == "--nvtop" ]]; then
    $term --title nvtop sh -c 'nvtop'
elif [[ "$1" == "--nmtui" ]]; then
    $term nmtui
elif [[ "$1" == "--term" ]]; then
    $term &
elif [[ "$1" == "--files" ]]; then
    $files &
else
    echo "Usage: $0 [--btop | --nvtop | --nmtui | --term]"
    echo "--btop       : Open btop in a new term"
    echo "--nvtop      : Open nvtop in a new term"
    echo "--nmtui      : Open nmtui in a new term"
    echo "--term   : Launch a term window"
    echo "--files  : Launch a file manager"
fi