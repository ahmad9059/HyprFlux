#!/bin/bash

# ===========================
# GRUB Theme Setup Module
# ===========================

setup_grub_theme() {
  print_section "Setting up GRUB Theme"
  
  echo -e "${ACTION} Checking for GRUB...${RESET}"

  if ! command_exists grub-install && ! command_exists grub-mkconfig; then
    echo -e "${WARN} GRUB not detected. Skipping GRUB theme installation.${RESET}"
    return 0
  fi

  echo -e "${OK} GRUB detected. Installing GRUB theme (Vimix)...${RESET}"

  if [[ ! -f "$GRUB_THEME_ARCHIVE" ]]; then
    echo -e "${ERROR} GRUB theme archive not found at $GRUB_THEME_ARCHIVE.${RESET}"
    log_message "ERROR" "GRUB theme archive not found"
    return 1
  fi

  # Create temporary directory and extract theme
  ensure_dir "$GRUB_THEME_DIR"
  
  if ! tar -xf "$GRUB_THEME_ARCHIVE" -C "$GRUB_THEME_DIR" >>"$LOG_FILE" 2>&1; then
    echo -e "${ERROR} Failed to extract GRUB theme archive.${RESET}"
    log_message "ERROR" "GRUB theme extraction failed"
    return 1
  fi

  # Find and run installer
  local install_path=$(find "$GRUB_THEME_DIR" -type f -name "install.sh" -exec dirname {} \; | head -n1)
  
  if [[ -n "$install_path" ]]; then
    echo -e "${ACTION} Running GRUB theme installer...${RESET}"
    
    if (cd "$install_path" && sudo bash ./install.sh >>"$LOG_FILE" 2>&1); then
      echo -e "${OK} GRUB theme installed successfully.${RESET}"
      log_message "INFO" "GRUB theme installation completed"
      return 0
    else
      echo -e "${ERROR} GRUB theme installer failed.${RESET}"
      log_message "ERROR" "GRUB theme installer failed"
      return 1
    fi
  else
    echo -e "${WARN} install.sh not found in extracted Vimix theme. Skipping.${RESET}"
    log_message "WARN" "GRUB theme installer not found"
    return 1
  fi
}