#!/bin/bash

# ===========================
# Neovim Setup Module
# ===========================

setup_neovim() {
  print_section "Setting up Neovim"
  
  echo -e "${ACTION} Installing Neovim config from ${REPO_URL_NVIM}...${RESET}"
  
  # Remove existing config if it exists
  if [[ -d "$NVIM_CONFIG_DIR" ]]; then
    rm -rf "$NVIM_CONFIG_DIR" >>"$LOG_FILE" 2>&1
  fi
  
  # Clone Neovim configuration
  if git clone "$REPO_URL_NVIM" "$NVIM_CONFIG_DIR" >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} Neovim config installed in ${NVIM_CONFIG_DIR}.${RESET}"
  else
    echo -e "${ERROR} Failed to clone Neovim config from ${REPO_URL_NVIM}.${RESET}"
    log_message "ERROR" "Neovim config clone failed"
    return 1
  fi
  
  # Setup Neovim plugins
  echo -e "${ACTION} Installing and Setting Up Neovim Lazy, Mason Packages...${RESET}"
  
  # Initialize Neovim to trigger plugin installation
  nvim --headless -c 'qa' >>"$LOG_FILE" 2>&1
  nvim --headless -c 'Lazy sync' -c 'qa' >>"$LOG_FILE" 2>&1
  
  echo -e "${OK} NvChad, plugins, and Mason packages installed successfully!${RESET}"
  log_message "INFO" "Neovim setup completed"
  return 0
}