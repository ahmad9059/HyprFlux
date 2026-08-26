#!/bin/bash
# 💫 https://github.com/ahmad9059/HyprFlux 💫 #
# Hyprland-Dots to download from main #


## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# HyprFlux: Hyprland-Dots is merged into the HyprFlux repo (no clone needed)
printf "${NOTE} Installing ${SKY_BLUE}HyprFlux Dots${RESET} (merged, pre-patched)....\n"

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../base-dots" && pwd)"

if [ -d "$DOTS_DIR" ]; then
  cd "$DOTS_DIR" || { echo -e "$ERROR Hyprland-Dots directory not found at $DOTS_DIR"; exit 1; }
  chmod +x copy.sh
  ./copy.sh
else
  echo -e "$ERROR Hyprland-Dots not found at $DOTS_DIR. Check your HyprFlux checkout."
fi

printf "\n%.0s" {1..2}