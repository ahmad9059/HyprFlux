#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Script for changing blurs on the fly (Hyprland >= 0.55 uses hyprctl eval)


STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${STATE}" == "2" ]; then
	hyprctl eval 'hl.config({ decoration = { blur = { size = 2, passes = 1 } } })'
 	notify-send -e -u low -i "text-x-generic" " Less Blur"
else
	hyprctl eval 'hl.config({ decoration = { blur = { size = 5, passes = 2 } } })'
  	notify-send -e -u low -i "dialog-information" " Normal Blur"
fi
