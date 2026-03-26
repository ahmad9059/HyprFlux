#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Game Mode. Turning off all animations

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ]; then
  hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"

  hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
  awww kill
  notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
  exit
else
  awww-daemon --format xrgb && awww img "$HOME/.config/rofi/.current_wallpaper" &
  sleep 0.1
  ${SCRIPTSDIR}/WallpaperAwww.sh
  sleep 0.5
  ${SCRIPTSDIR}/Refresh.sh
  notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
  exit
fi
hyprctl reload
