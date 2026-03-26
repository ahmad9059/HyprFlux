#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Sync current awww wallpaper to rofi preview and wallpaper_effects cache

# Path to awww cache
cache_dir="$HOME/.cache/awww/"

# Get current focused monitor
current_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

# Full path to the cache file for this monitor
cache_file="${cache_dir}${current_monitor}"

if [ -f "$cache_file" ]; then
    # Read the wallpaper path from awww's cache
    wallpaper_path=$(grep -v 'Lanczos3' "$cache_file" | head -n 1)

    # Symlink wallpaper so rofi can use it as a preview
    ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"

    # Copy wallpaper for wallpaper effects scripts
    mkdir -p "$HOME/.config/hypr/wallpaper_effects"
    cp -f "$wallpaper_path" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
fi
