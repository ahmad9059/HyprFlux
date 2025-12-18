#!/bin/bash

set -e

# ===========================
# HyprFlux Installer
# Modular Version with Backward Compatibility
# ===========================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if modular system is available
if [[ -f "$SCRIPT_DIR/lib/colors.sh" && -f "$SCRIPT_DIR/lib/utils.sh" && -f "$SCRIPT_DIR/lib/config.sh" ]]; then
  # Use modular system
  echo "Using modular installer..."
  exec bash "$SCRIPT_DIR/install_modular.sh" "$@"
fi

# Fallback to legacy monolithic system
echo "Using legacy installer..."

# ===========================
# Color-coded status labels
# ===========================
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
OK="$(tput setaf 2)[OK]$(tput sgr0)"
NOTE="$(tput setaf 6)[NOTE]$(tput sgr0)"
ACTION="$(tput setaf 5)[ACTION]$(tput sgr0)"
RESET="$(tput sgr0)"
CYAN="$(tput setaf 6)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"

# ===========================
# Log Details
# ===========================
mkdir -p "$HOME/hyprflux_log"
LOG_FILE="$HOME/hyprflux_log/install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ==========================
# Initial Bannar
# =========================

clear
echo -e "\n"
echo -e "${CYAN}     ██╗  ██╗██╗   ██╗██████╗ ██████╗ ███████╗██╗     ██╗   ██╗██╗  ██╗${RESET}"
echo -e "${CYAN}     ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║     ██║   ██║╚██╗██╔╝${RESET}"
echo -e "${CYAN}     ███████║ ╚████╔╝ ██████╔╝██████╔╝█████╗  ██║     ██║   ██║ ╚███╔╝ ${RESET}"
echo -e "${CYAN}     ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║ ██╔██╗ ${RESET}"
echo -e "${CYAN}     ██║  ██║   ██║   ██║     ██║  ██║██║     ███████╗╚██████╔╝██╔╝ ██╗${RESET}"
echo -e "${CYAN}     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝${RESET}"
echo -e "${RED}     ✻────────────────────────────ahmad9059────────────────────────────✻${RESET}"
echo -e "${GREEN}           Welcome to HyprFlux! lets begin Installation 👋 ${RESET}"
echo -e "\n"

# ===========================
# Define script directory
# ===========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===========================
# Ask for sudo once, keep it alive
# ===========================
echo "${NOTE} Asking for sudo password^^...${RESET}"
sudo -v

keep_sudo_alive() {
  while true; do
    sudo -n true
    sleep 30
  done
}
keep_sudo_alive &
SUDO_KEEP_ALIVE_PID=$!
trap 'kill $SUDO_KEEP_ALIVE_PID' EXIT

# ===========================
# Clone Arch-Hyprland repo
# ===========================
if [ -d "$HOME/Arch-Hyprland" ]; then
  echo "${NOTE} Folder 'Arch-Hyprland' already exists in HOME, using it...${RESET}"
else
  echo "${NOTE} Cloning Arch-Hyprland repo into HOME...${RESET}"
  if git clone --depth=1 https://github.com/ahmad9059/Arch-Hyprland.git "$HOME/Arch-Hyprland"; then
    echo "${OK} Repo cloned successfully.${RESET}"
  else
    echo "${ERROR} Failed to clone Arch-Hyprland repo. Exiting.${RESET}"
    exit 1
  fi
fi

# ===========================
# Run Arch-Hyprland installer
# ===========================
echo "${NOTE} Running Arch-Hyprland/install.sh with preset answers...${RESET}"
cd "$HOME/Arch-Hyprland"
sed -i '/^[[:space:]]*read HYP$/c\HYP="n"' ~/Arch-Hyprland/install.sh
# sed -i '/# Ensuring base-devel is installed/{N;N;N;a \
# sleep 1\n\
# \n\
# # Custom Script\n\
# wget -q -O ~/Arch-Hyprland/install-scripts/zsh.sh https://raw.githubusercontent.com/ahmad9059/Scripts/main/zsh.sh\n\
# wget -q -O /tmp/replace_reads.sh https://raw.githubusercontent.com/ahmad9059/Scripts/main/replace_reads.sh\n\
# chmod +x /tmp/replace_reads.sh\n\
# bash /tmp/replace_reads.sh
# }' ~/Arch-Hyprland/install.sh

chmod +x install.sh
bash install.sh
echo "${OK} Arch-Hyprland script Installed!${RESET}"

# ===========================
# HyprFlux Banner
# ===========================
clear

echo -e "\n"
echo -e "${MAGENTA}┌┬┐┌─┐┌┬┐┌─┐┬┬  ┌─┐┌─┐┌─┐  ┬┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐${RESET}"
echo -e "${MAGENTA} │││ │ │ ├┤ ││  ├┤ └─┐└─┐  ││││└─┐ │ ├─┤│  │  ├┤ ├┬┘${RESET}"
echo -e "${MAGENTA}─┴┘└─┘ ┴ └  ┴┴─┘└─┘└─┘└─┘  ┴┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─${RESET}"
echo -e "${CYAN}✻─────────────────────ahmad9059──────────────────────✻${RESET}"
echo -e "\n"

# ===========================
# Clone HyprFlux repo
# ===========================
if [ -d "$HOME/HyprFlux" ]; then
  echo "${NOTE} Folder 'HyprFlux' already exists in HOME, using it...${RESET}"
else
  echo "${NOTE} Cloning HyprFlux repo into ~...${RESET}"
  if git clone --depth=1 https://github.com/ahmad9059/HyprFlux.git "$HOME/HyprFlux"; then
    echo "${OK} Repo cloned successfully.${RESET}"
  else
    echo "${ERROR} Failed to clone HyprFlux repo. Exiting.${RESET}"
    exit 1
  fi
fi

# ===========================
# Run HyprFlux installer
# ===========================
echo "${NOTE} Running HyprFlux dotsSetup.sh...${RESET}"
cd "$HOME/HyprFlux"
# git checkout personal
chmod +x dotsSetup.sh
bash dotsSetup.sh

# ===========================
# Ask for Reboot
# ===========================

read -p "Do you want to reboot now? [y/N]: " REBOOT_CHOICE

if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
  echo "$OK Rebooting..."
  sudo reboot
else
  echo "$OK You chose NOT to reboot. Please reboot later."
fi
