#!/bin/bash

# ===========================
# Wallpapers Setup Module
# ===========================

setup_wallpapers() {
  print_section "Setting up Wallpapers"
  
  echo -e "${ACTION} Updating wallpapers and setup...${RESET}"
  
  # Remove old wallpapers folder if exists
  if [[ -d "$WALLPAPER_DIR" ]]; then
    rm -rf "$WALLPAPER_DIR"
  fi
  
  # Clone wallpapers with retry logic
  local attempt=1
  local max_attempts=5
  
  while [[ $attempt -le $max_attempts ]]; do
    echo -e "${ACTION} Cloning wallpapers repository (attempt $attempt/$max_attempts)...${RESET}"
    
    if git clone --depth=1 "$WALLPAPER_REPO" "$WALLPAPER_DIR" >>"$LOG_FILE" 2>&1; then
      echo -e "${OK} Wallpapers cloned successfully to $WALLPAPER_DIR${RESET}"
      log_message "INFO" "Wallpapers setup completed"
      return 0
    else
      echo -e "${WARN} Clone failed, retrying in 5 seconds...${RESET}"
      sleep 5
      ((attempt++))
    fi
  done
  
  echo -e "${ERROR} Failed to clone wallpapers after $max_attempts attempts.${RESET}"
  log_message "ERROR" "Wallpapers setup failed"
  return 1
}