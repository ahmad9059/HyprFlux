#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Game Mode. Turning off all animations (Hyprland >= 0.55 uses hyprctl eval)
# Disable path uses `hyprctl config full-reload` to restore every value from
# hyprland.lua (this is what the original script's trailing `hyprctl reload`
# line was meant to do but never reached).

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ]; then
  hyprctl eval 'hl.config({
    animations = { enabled = false },
    decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 },
    general = { gaps_in = 0, gaps_out = 0, border_size = 1 }
  })'

  # Force full opacity on every window; pcall makes re-enabling idempotent
  # (the rule is wiped by the full-reload on the disable path).
  hyprctl eval 'pcall(function() hl.window_rule({ name = "gamemode-opacity", match = { class = ".*" }, opacity = "1 override 1 override 1 override" }) end)'
  awww kill
  notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
  exit
else
  awww-daemon --format xrgb && awww img "$HOME/.config/rofi/.current_wallpaper" &
  sleep 0.1
  ${SCRIPTSDIR}/WallpaperAwww.sh
  sleep 0.5
  ${SCRIPTSDIR}/Refresh.sh
  # restore all config values + remove runtime window rules from the Lua config
  hyprctl config full-reload
  notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
  exit
fi
