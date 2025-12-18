#!/bin/bash

# ===========================
# Logging Module
# ===========================

setup_logging() {
  local script_dir="$(get_script_dir)"
  source "$script_dir/lib/config.sh"
  source "$script_dir/lib/colors.sh"
  
  # Create log directory
  ensure_dir "$LOG_DIR"
  
  # Setup logging to file and stdout
  exec > >(tee -a "$LOG_FILE") 2>&1
  
  echo -e "${OK} Logging initialized: $LOG_FILE${RESET}"
  log_message "INFO" "HyprFlux dotfiles setup started"
}