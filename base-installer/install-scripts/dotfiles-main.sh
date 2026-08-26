#!/bin/bash
# https://github.com/ahmad9059/HyprFlux #
# base-dots deployment — single-source note #

# ============================================================
# HyprFlux: base-dots/config is byte-identical to the HyprFlux
# repo's .config/ (parity enforced by CI). Config deployment is
# done ONCE by dotsSetup module 02-dotfiles (copies .config/ to
# ~/.config/). Running base-dots/copy.sh here would be a second,
# redundant copy of the same files — so it is intentionally NOT
# executed. This script only verifies the merged checkout is
# complete, then hands off to module 02.
# ============================================================

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Unified logging: standalone-safe fallback (install.sh exports the variable;
# the ISO chroot wrapper runs this script directly, so default it here too).
LOG="${HYPRFLUX_LOGS_DIR:-$HOME/HyprFlux/logs}/installer/install-$(date +%d-%H%M%S)_dots.log"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

printf "${NOTE} Verifying merged base-dots checkout...${RESET}\n"

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../base-dots" && pwd)"
HYPRFLUX_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.config" && pwd)"

if [ ! -d "$DOTS_DIR" ]; then
  echo -e "$ERROR base-dots not found at $DOTS_DIR. Check your HyprFlux checkout."
  exit 1
fi

if [ ! -d "$HYPRFLUX_CONFIG_DIR" ]; then
  echo -e "$ERROR .config not found at $HYPRFLUX_CONFIG_DIR. Check your HyprFlux checkout."
  exit 1
fi

# Guard against accidental divergence: if base-dots/config ever drifts from
# .config/, warn loudly (CI also enforces this).
if ! diff -rq "$HYPRFLUX_CONFIG_DIR" "$DOTS_DIR/config" >/dev/null 2>&1; then
  echo -e "$WARN base-dots/config differs from .config/ — .config/ is the source of truth." 2>&1 | tee -a "$LOG"
fi

echo "${OK} base-dots verified — config will be deployed by dotsSetup module 02 (single source)." 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}