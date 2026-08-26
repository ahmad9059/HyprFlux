#!/bin/bash
# https://github.com/ahmad9059/HyprFlux #
# Yay AUR Helper #
# NOTE: If paru is already installed, yay will not be installed #

pkg="yay-bin"

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
# Set the name of the log file to include the current date and time
LOG="$HYPRFLUX_LOGS_DIR/installer/install-$(date +%d-%H%M%S)_yay.log"

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Create Directory for Install Logs
mkdir -p "${HYPRFLUX_LOGS_DIR:-$HOME/HyprFlux/logs}/installer"

# Check for AUR helper and install if not found
ISAUR=$(command -v yay || command -v paru)
if [ -n "$ISAUR" ]; then
  printf "\n%s - ${SKY_BLUE}AUR helper${RESET} already installed, moving on.\n" "${OK}"
else
  printf "\n%s - Installing ${SKY_BLUE}$pkg${RESET} from AUR\n" "${NOTE}"

# Check if directory exists and remove it
if [ -d "$pkg" ]; then
    rm -rf "$pkg"
fi
  git clone https://aur.archlinux.org/$pkg.git || { printf "%s - Failed to clone ${YELLOW}$pkg${RESET} from AUR\n" "${ERROR}"; exit 1; }
  cd $pkg || { printf "%s - Failed to enter $pkg directory\n" "${ERROR}"; exit 1; }
  makepkg -si --noconfirm 2>&1 | tee -a "$LOG" || { printf "%s - Failed to install ${YELLOW}$pkg${RESET} from AUR\n" "${ERROR}"; exit 1; }

  # moving build logs into the unified log tree
  mv install*.log "${HYPRFLUX_LOGS_DIR:-$HOME/HyprFlux/logs}/installer/" || true
  cd ..
fi

# Only refresh the package DB if we JUST installed the helper here.
# (HyprFlux/install.sh already ran a full -Syu before this step, so a second
# full upgrade here would be pure duplicate work and can hit lock conflicts.)
ISAUR=$(command -v yay || command -v paru)
if [ -n "$ISAUR" ]; then
  $ISAUR -Sy --noconfirm 2>&1 | tee -a "$LOG" || true
else
  sudo pacman -Sy --noconfirm 2>&1 | tee -a "$LOG" || true
fi

printf "\n%.0s" {1..2}