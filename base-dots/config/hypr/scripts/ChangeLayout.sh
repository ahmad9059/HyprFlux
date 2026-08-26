#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Cycle Hyprland layout (Dwindle ↔ Master ↔ Scrolling) on the fly.
# No runtime unbind/rebind — cycling binds live in the static config
# (configs/keybinds.lua, layout-aware), so no other binds get clobbered.

notif="dialog-information"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

case $LAYOUT in
"master")
    next="scrolling"
    msg="Scrolling Layout"
    ;;
"scrolling")
    next="dwindle"
    msg="Dwindle Layout"
    ;;
"dwindle"|*)
    next="master"
    msg="Master Layout"
    ;;
esac

hyprctl eval "hl.config({ general = { layout = \"$next\" } })"
notify-send -e -u low -i "$notif" " $msg"
