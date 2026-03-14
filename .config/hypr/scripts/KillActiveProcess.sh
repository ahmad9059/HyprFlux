#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Copied from Discord post. Thanks to @Zorg


# Get id of an active window
active_pid=$(hyprctl activewindow | grep -o 'pid: [0-9]*' | cut -d' ' -f2)

# Close active window
kill $active_pid