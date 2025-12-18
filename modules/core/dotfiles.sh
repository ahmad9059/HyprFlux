#!/bin/bash

# ===========================
# Dotfiles Management Module
# ===========================

# Clone the HyprFlux repository
clone_repository() {
  print_section "Cloning HyprFlux Repository"
  
  echo -e "${ACTION} Cloning dotfiles into ${REPO_DIR}...${RESET}"
  
  # If repo folder already exists
  if [[ -d "$REPO_DIR" ]]; then
    echo -e "${NOTE} Folder ${REPO_DIR} already exists. Skipping clone.${RESET}"
    return 0
  fi
  
  if git clone "$REPO_URL" "$REPO_DIR" &>>"$LOG_FILE"; then
    echo -e "${OK} Dotfiles cloned successfully to ${REPO_DIR}.${RESET}"
    log_message "INFO" "Repository cloned successfully"
    return 0
  else
    echo -e "${ERROR} Failed to clone dotfiles repo from ${REPO_URL}.${RESET}"
    log_message "ERROR" "Repository clone failed"
    return 1
  fi
}

# Remove old config folders before copying new ones
remove_old_configs() {
  print_section "Cleaning Old Configurations"
  
  echo -e "${ACTION} Removing old config folders from ~/.config that are in ${REPO_DIR}...${RESET}"
  
  if [[ ! -d "$REPO_DIR/.config" ]]; then
    echo -e "${WARN} No .config folder found in ${REPO_DIR}, skipping removal.${RESET}"
    return 0
  fi
  
  for folder in "$REPO_DIR/.config/"*; do
    if [[ -d "$folder" ]]; then
      local folder_name=$(basename "$folder")
      if [[ -d "$HOME/.config/$folder_name" ]]; then
        rm -rf "$HOME/.config/$folder_name" &>>"$LOG_FILE"
        echo -e "${OK} Removed old config: $folder_name${RESET}"
      fi
    fi
  done
  
  echo -e "${OK} Old config folders removed successfully.${RESET}"
  log_message "INFO" "Old configurations cleaned"
  return 0
}

# Copy new dotfiles
copy_dotfiles() {
  print_section "Copying New Dotfiles"
  
  echo -e "${ACTION} Copying new dotfiles...${RESET}"
  
  if [[ ! -d "$REPO_DIR/.config" ]]; then
    echo -e "${ERROR} '$REPO_DIR/.config' does not exist. Dotfiles not copied.${RESET}"
    log_message "ERROR" "Source .config directory not found"
    return 1
  fi
  
  # Ensure .config directory exists
  ensure_dir "$HOME/.config"
  
  # Copy files
  {
    cp -r "$REPO_DIR/.config/"* "$HOME/.config/"
    [[ -f "$REPO_DIR/.zshrc" ]] && cp "$REPO_DIR/.zshrc" "$HOME/"
    [[ -f "$REPO_DIR/.tmux.conf" ]] && cp "$REPO_DIR/.tmux.conf" "$HOME/"
  } >>"$LOG_FILE" 2>&1
  
  if [[ $? -eq 0 ]]; then
    echo -e "${OK} HyprFlux dotfiles copied successfully.${RESET}"
    log_message "INFO" "Dotfiles copied successfully"
    return 0
  else
    echo -e "${ERROR} Failed to copy one or more dotfiles. Check $LOG_FILE for details.${RESET}"
    log_message "ERROR" "Dotfiles copy failed"
    return 1
  fi
}

# Main dotfiles setup function
setup_dotfiles() {
  clone_repository || return 1
  remove_old_configs || return 1
  copy_dotfiles || return 1
  return 0
}