#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# for changing Hyprland Layouts (Master or Dwindle) on the fly
# (Hyprland >= 0.55: hyprctl keyword → hyprctl eval)

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

case $LAYOUT in
"master")
	hyprctl eval 'hl.config({ general = { layout = "dwindle" } })'
	hyprctl eval 'hl.unbind("SUPER + J"); hl.unbind("SUPER + K");
		hl.bind("SUPER + J", hl.dsp.window.cycle_next({ next = true }));
		hl.bind("SUPER + K", hl.dsp.window.cycle_next({ next = false }));
		hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))'
  notify-send -e -u low -i "$notif" " Dwindle Layout"
	;;
"dwindle")
	hyprctl eval 'hl.config({ general = { layout = "master" } })'
	hyprctl eval 'hl.unbind("SUPER + J"); hl.unbind("SUPER + K"); hl.unbind("SUPER + O");
		hl.bind("SUPER + J", hl.dsp.layout("cyclenext"));
		hl.bind("SUPER + K", hl.dsp.layout("cycleprev"))'
  notify-send -e -u low -i "$notif" " Master Layout"
	;;
*) ;;

esac
