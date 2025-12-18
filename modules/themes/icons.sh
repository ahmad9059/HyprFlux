#!/bin/bash

# ===========================
# Icon Theme Setup Module
# ===========================

setup_icon_theme() {
  print_section "Setting up Icon Theme"
  
  if ! command_exists yay; then
    echo -e "${WARN} yay not found. Skipping icon theme installation.${RESET}"
    return 0
  fi

  echo -e "${ACTION} Installing 'papirus-icon-theme' via pacman...${RESET}"
  
  if sudo pacman -S --needed --noconfirm papirus-icon-theme papirus-folders >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} 'papirus-icon-theme' installed successfully.${RESET}"

    # Set folder color to cyan for Papirus-Dark
    echo -e "${ACTION} Setting Papirus folders to cyan (Papirus-Dark).${RESET}"
    if papirus-folders -C cyan --theme Papirus-Dark &>>"$LOG_FILE"; then
      echo -e "${OK} Papirus folders set to cyan (Papirus-Dark).${RESET}"
    else
      echo -e "${WARN} Failed to set Papirus folder colors.${RESET}"
    fi

    log_message "INFO" "Icon theme setup completed"
    return 0
  else
    echo -e "${ERROR} Failed to install 'papirus-icon-theme'. Check $LOG_FILE for details.${RESET}"
    log_message "ERROR" "Icon theme installation failed"
    return 1
  fi
}