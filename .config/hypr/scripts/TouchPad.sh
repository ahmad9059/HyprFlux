#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# For disabling touchpad (Hyprland >= 0.55: hyprctl eval re-applies hl.device).
# Edit the Touchpad_Device below AND in ~/.config/hypr/UserConfigs/laptops.lua
# according to your system. Use `hyprctl devices` to get your touchpad name.
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

notif="$HOME/.config/swaync/images/ja.png"

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

TOUCHPAD_DEVICE="asue1209:00-04f3:319f-touchpad"

enable_touchpad() {
    printf "true" >"$STATUS_FILE"
    notify-send -u low -i $notif  " Enabling" " touchpad"
    hyprctl eval 'hl.device({ name = "'"$TOUCHPAD_DEVICE"'", enabled = true })'
}

disable_touchpad() {
    printf "false" >"$STATUS_FILE"
    notify-send -u low -i $notif " Disabling" " touchpad"
    hyprctl eval 'hl.device({ name = "'"$TOUCHPAD_DEVICE"'", enabled = false })'
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi
