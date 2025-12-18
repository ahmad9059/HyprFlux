#!/bin/bash

set -e

# ===========================
# HyprFlux Modular Installer
# ===========================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared libraries
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/config.sh"

# ===========================
# Banner Display
# ===========================

show_banner() {
  clear
  echo -e "\n"
  echo -e "${CYAN}     ██╗  ██╗██╗   ██╗██████╗ ██████╗ ███████╗██╗     ██╗   ██╗██╗  ██╗${RESET}"
  echo -e "${CYAN}     ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║     ██║   ██║╚██╗██╔╝${RESET}"
  echo -e "${CYAN}     ███████║ ╚████╔╝ ██████╔╝██████╔╝█████╗  ██║     ██║   ██║ ╚███╔╝ ${RESET}"
  echo -e "${CYAN}     ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║ ██╔██╗ ${RESET}"
  echo -e "${CYAN}     ██║  ██║   ██║   ██║     ██║  ██║██║     ███████╗╚██████╔╝██╔╝ ██╗${RESET}"
  echo -e "${CYAN}     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝${RESET}"
  echo -e "${RED}     ✻────────────────────────────ahmad9059────────────────────────────✻${RESET}"
  echo -e "${GREEN}           Welcome to HyprFlux! Let's begin Installation 👋 ${RESET}"
  echo -e "\n"
}

# ===========================
# Arch-Hyprland Setup
# ===========================

setup_arch_hyprland() {
  print_section "Setting up Arch-Hyprland Base"
  
  local arch_hyprland_dir="$HOME/Arch-Hyprland"
  
  if [[ -d "$arch_hyprland_dir" ]]; then
    echo -e "${NOTE} Folder 'Arch-Hyprland' already exists in HOME, using it...${RESET}"
  else
    echo -e "${NOTE} Cloning Arch-Hyprland repo into HOME...${RESET}"
    if git clone --depth=1 https://github.com/ahmad9059/Arch-Hyprland.git "$arch_hyprland_dir" >>"$LOG_FILE" 2>&1; then
      echo -e "${OK} Repo cloned successfully.${RESET}"
    else
      echo -e "${ERROR} Failed to clone Arch-Hyprland repo. Exiting.${RESET}"
      return 1
    fi
  fi
  
  # Run Arch-Hyprland installer with preset answers
  echo -e "${NOTE} Running Arch-Hyprland/install.sh with preset answers...${RESET}"
  
  cd "$arch_hyprland_dir"
  
  # Modify the script to skip interactive prompts
  sed -i '/^[[:space:]]*read HYP$/c\HYP="n"' "$arch_hyprland_dir/install.sh"
  
  chmod +x install.sh
  
  if bash install.sh >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} Arch-Hyprland script installed successfully!${RESET}"
    log_message "INFO" "Arch-Hyprland base setup completed"
    return 0
  else
    echo -e "${ERROR} Arch-Hyprland installation failed.${RESET}"
    log_message "ERROR" "Arch-Hyprland base setup failed"
    return 1
  fi
}

# ===========================
# HyprFlux Setup
# ===========================

setup_hyprflux() {
  print_section "Setting up HyprFlux Dotfiles"
  
  # Show HyprFlux banner
  clear
  echo -e "\n"
  echo -e "${MAGENTA}┌┬┐┌─┐┌┬┐┌─┐┬┬  ┌─┐┌─┐┌─┐  ┬┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐${RESET}"
  echo -e "${MAGENTA} │││ │ │ ├┤ ││  ├┤ └─┐└─┐  ││││└─┐ │ ├─┤│  │  ├┤ ├┬┘${RESET}"
  echo -e "${MAGENTA}─┴┘└─┘ ┴ └  ┴┴─┘└─┘└─┘└─┘  ┴┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─${RESET}"
  echo -e "${CYAN}✻─────────────────────ahmad9059──────────────────────✻${RESET}"
  echo -e "\n"
  
  # Clone HyprFlux repository if needed
  if [[ -d "$HOME/HyprFlux" ]]; then
    echo -e "${NOTE} Folder 'HyprFlux' already exists in HOME, using it...${RESET}"
  else
    echo -e "${NOTE} Cloning HyprFlux repo into ~...${RESET}"
    if git clone --depth=1 https://github.com/ahmad9059/HyprFlux.git "$HOME/HyprFlux" >>"$LOG_FILE" 2>&1; then
      echo -e "${OK} Repo cloned successfully.${RESET}"
    else
      echo -e "${ERROR} Failed to clone HyprFlux repo. Exiting.${RESET}"
      return 1
    fi
  fi
  
  # Run HyprFlux modular installer
  echo -e "${NOTE} Running HyprFlux modular setup...${RESET}"
  
  cd "$HOME/HyprFlux"
  
  # Use the modular setup script
  local setup_script="dotsSetup_modular.sh"
  if [[ -f "$setup_script" ]]; then
    chmod +x "$setup_script"
    if bash "$setup_script"; then
      echo -e "${OK} HyprFlux setup completed successfully!${RESET}"
      log_message "INFO" "HyprFlux setup completed"
      return 0
    else
      echo -e "${ERROR} HyprFlux setup failed.${RESET}"
      log_message "ERROR" "HyprFlux setup failed"
      return 1
    fi
  else
    echo -e "${ERROR} Modular setup script not found: $setup_script${RESET}"
    return 1
  fi
}

# ===========================
# Reboot Prompt
# ===========================

prompt_reboot() {
  print_section "Installation Complete"
  
  echo -e "${OK} HyprFlux installation completed successfully!${RESET}"
  echo -e "${NOTE} It's recommended to reboot to ensure all changes take effect.${RESET}"
  
  if ask_yes_no "Do you want to reboot now?"; then
    echo -e "${OK} Rebooting system...${RESET}"
    sudo reboot
  else
    echo -e "${OK} You chose not to reboot. Please reboot later to see all changes.${RESET}"
    echo -e "${NOTE} After reboot, you can enjoy your new HyprFlux desktop environment!${RESET}"
  fi
}

# ===========================
# Main Installation Function
# ===========================

main() {
  # Check system compatibility
  check_arch_linux
  check_internet
  
  # Initialize logging and sudo
  ensure_dir "$LOG_DIR"
  exec > >(tee -a "$LOG_FILE") 2>&1
  
  start_sudo_keepalive
  
  # Show welcome banner
  show_banner
  
  log_message "INFO" "HyprFlux installation started"
  
  # Run installation steps
  if setup_arch_hyprland && setup_hyprflux; then
    log_message "INFO" "HyprFlux installation completed successfully"
    prompt_reboot
  else
    echo -e "${ERROR} Installation failed. Check $LOG_FILE for details.${RESET}"
    log_message "ERROR" "HyprFlux installation failed"
    exit 1
  fi
  
  # Cleanup
  stop_sudo_keepalive
}

# ===========================
# Script Entry Point
# ===========================

# Handle script arguments
case "${1:-}" in
  --help|-h)
    echo "HyprFlux Modular Installer"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo "  --version, -v Show version information"
    exit 0
    ;;
  --version|-v)
    echo "HyprFlux Installer v2.0 (Modular)"
    exit 0
    ;;
  *)
    main "$@"
    ;;
esac