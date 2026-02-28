#!/bin/bash
# ============================================================
# install.sh — HyprFlux top-level entry point
# ============================================================
# 1. Sources shared libraries
# 2. Clones Arch-Hyprland and runs its installer
# 3. Clones/uses HyprFlux and runs dotsSetup.sh
# 4. Asks for reboot
# ============================================================

set -e

# ====== Resolve paths ======
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ====== Source shared libraries ======
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/git.sh"

# ====== Logging ======
setup_logging "$HOME/hyprflux_log/install.log"

# ====== Banner ======
clear
echo -e "\n"
echo -e "${CYAN}     ██╗  ██╗██╗   ██╗██████╗ ██████╗ ███████╗██╗     ██╗   ██╗██╗  ██╗${RESET}"
echo -e "${CYAN}     ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║     ██║   ██║╚██╗██╔╝${RESET}"
echo -e "${CYAN}     ███████║ ╚████╔╝ ██████╔╝██████╔╝█████╗  ██║     ██║   ██║ ╚███╔╝ ${RESET}"
echo -e "${CYAN}     ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║ ██╔██╗ ${RESET}"
echo -e "${CYAN}     ██║  ██║   ██║   ██║     ██║  ██║██║     ███████╗╚██████╔╝██╔╝ ██╗${RESET}"
echo -e "${CYAN}     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝${RESET}"
echo -e "${RED}     ✻────────────────────────────ahmad9059────────────────────────────✻${RESET}"
echo -e "${GREEN}           Welcome to HyprFlux! lets begin Installation${RESET}"
echo -e "\n"

# ====== Sudo ======
setup_sudo

# ====== Configurable URLs ======
ARCH_HYPRLAND_REPO="${ARCH_HYPRLAND_REPO:-https://github.com/ahmad9059/Arch-Hyprland.git}"
ARCH_HYPRLAND_DIR="${ARCH_HYPRLAND_DIR:-$HOME/Arch-Hyprland}"
HYPRFLUX_REPO="${HYPRFLUX_REPO:-https://github.com/ahmad9059/HyprFlux.git}"
HYPRFLUX_DIR="${HYPRFLUX_DIR:-$HOME/HyprFlux}"

# ====== Step 1: Clone & run Arch-Hyprland ======
ensure_repo "$ARCH_HYPRLAND_REPO" "$ARCH_HYPRLAND_DIR" --depth=1

log_info "Running Arch-Hyprland/install.sh with preset answers..."
sed -i '/^[[:space:]]*read HYP$/c\HYP="n"' "$ARCH_HYPRLAND_DIR/install.sh"
chmod +x "$ARCH_HYPRLAND_DIR/install.sh"
# IMPORTANT: Must cd into the directory because Arch-Hyprland's install.sh
# uses relative paths (e.g., install-scripts/) that only resolve from there.
(cd "$ARCH_HYPRLAND_DIR" && bash install.sh)
log_ok "Arch-Hyprland script installed!"

# ====== Step 2: HyprFlux banner ======
clear
echo -e "\n"
echo -e "${MAGENTA}┌┬┐┌─┐┌┬┐┌─┐┬┬  ┌─┐┌─┐┌─┐  ┬┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐${RESET}"
echo -e "${MAGENTA} │││ │ │ ├┤ ││  ├┤ └─┐└─┐  ││││└─┐ │ ├─┤│  │  ├┤ ├┬┘${RESET}"
echo -e "${MAGENTA}─┴┘└─┘ ┴ └  ┴┴─┘└─┘└─┘└─┘  ┴┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─${RESET}"
echo -e "${CYAN}✻─────────────────────ahmad9059──────────────────────✻${RESET}"
echo -e "\n"

# ====== Step 3: Clone & run HyprFlux dotsSetup ======
ensure_repo "$HYPRFLUX_REPO" "$HYPRFLUX_DIR" --depth=1

log_info "Running HyprFlux dotsSetup.sh..."
chmod +x "$HYPRFLUX_DIR/dotsSetup.sh"
bash "$HYPRFLUX_DIR/dotsSetup.sh"

# ====== Step 4: Reboot prompt ======
# BUG FIX: added -r flag to read
if ask_yes_no "Do you want to reboot now?"; then
  log_ok "Rebooting..."
  sudo reboot
else
  log_ok "You chose NOT to reboot. Please reboot later."
fi
