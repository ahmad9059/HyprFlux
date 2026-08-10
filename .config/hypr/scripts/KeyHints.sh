#!/bin/bash

# GDK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

# Kill rofi/yad if running
if pidof rofi >/dev/null; then pkill rofi; fi
if pidof yad >/dev/null; then pkill yad; fi

# Launch yad with keybinds
GDK_BACKEND=$BACKEND yad \
  --center \
  --title="Hyprland Quick Cheat Sheet" \
  --no-buttons \
  --list \
  --column="Key:" \
  --column="Description:" \
  --timeout-indicator=bottom \
  " + Q" "Close active window (not kill)" \
  " + SHIFT + Q" "Kill active process" \
  "CTRL + ALT + L" "Lock screen" \
  "CTRL + ALT + P" "Power menu" \
  " + N" "SwayNC notification panel" \
  " + SHIFT + E" "Hyprland settings menu" \
  " + D" "App Launcher (rofi)" \
  " + Return" "Terminal" \
  " + F" "File Manager" \
  " + K" "Launch Kdenlive" \
  " + B" "Launch Firefox" \
  " + R" "Launch Foliate eBook reader" \
  " + V" "Clipboard Manager" \
  " + C" "Launch Visual Studio Code" \
  " + O" "Launch Obsidian" \
  " + S" "Spotify" \
  " + X" "Vesktop (Discord)" \
  " + T" "Telegram" \
  " + M" "Free Download Manager" \
  " + E" "Tmuxifier (web-dev session)" \
  " + W" "Whatsapp-Linux" \
  "ALT + N" "Network Manager GUI" \
  " + SHIFT + H" "Cheat Sheet (this)" \
  " + SHIFT + R" "Refresh Waybar, SwayNC, Rofi" \
  " + SHIFT + O" "Toggle Blur settings" \
  " + SHIFT + G" "Mount Google Drive" \
  " + SHIFT + T" "Toggle Tuned" \
  " + SHIFT + D" "Sync dotfiles" \
  " + SHIFT + B" "Sync blog" \
  " + SHIFT + C" "Sync Documents to Google Drive" \
  " + SHIFT + L" "Toggle Master/Dwindle layout" \
  " + SHIFT + P" "Color Picker (Hyprpicker)" \
  " + SHIFT + V" "Run ParrotOS-KVM script" \
  " + SHIFT + F" "Fullscreen" \
  " + SHIFT + Return" "Dropdown terminal" \
  " + CTRL + F" "Fake fullscreen" \
  " + SPACE" "Toggle floating window" \
  " + ALT + SPACE" "All windows floating" \
  " + ALT + E" "Emoji Menu" \
  " + CTRL + ALT + B" "Toggle Waybar (hide/show)" \
  " + CTRL + B" "Waybar Styles Menu" \
  " + ALT + B" "Waybar Layout Menu" \
  " + SHIFT + M" "Rofi Beats (music)" \
  " + SHIFT + W" "Wallpaper Select" \
  "CTRL + ALT + W" "Random Wallpaper" \
  " + CTRL + O" "Toggle opacity (active window)" \
  " + SHIFT + K" "Search Keybinds (Rofi)" \
  " + SHIFT + A" "Animations Menu" \
  " + SHIFT + Z" "Change Zsh theme" \
  " + CTRL + C" "Rofi Calculator" \
  " + Print" "Screenshot (now)" \
  " + SHIFT + Print" "Screenshot (area)" \
  " + CTRL + Print" "Screenshot (5s delay)" \
  " + CTRL + SHIFT + Print" "Screenshot (10s delay)" \
  "ALT + Print" "Screenshot (active window)" \
  " + SHIFT + S" "Screenshot (Swappy)" \
  " + ALT + mouse_down" "Zoom in (desktop magnifier)" \
  " + ALT + mouse_up" "Zoom out (desktop magnifier)" \
  "" "More at ~/.config/hypr/UserConfigs and UserScripts"
