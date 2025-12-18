#!/bin/bash

# ===========================
# Backup Module
# ===========================

backup_existing_configs() {
  print_section "Backing up existing configurations"
  
  echo -e "${ACTION} Backing up existing dotfiles to ${BACKUP_DIR}...${RESET}"
  
  # Remove existing backup if it exists
  if [[ -d "$BACKUP_DIR" ]]; then
    echo -e "${ACTION} Existing backup found. Removing old backup...${RESET}"
    rm -rf "$BACKUP_DIR" &>>"$LOG_FILE"
  fi
  
  if ! ensure_dir "$BACKUP_DIR"; then
    echo -e "${ERROR} Failed to create backup directory at ${BACKUP_DIR}.${RESET}"
    return 1
  fi
  
  # Backup important configs
  backup_item "$HOME/.config" "$BACKUP_DIR"
  backup_item "$HOME/.zshrc" "$BACKUP_DIR"
  backup_item "$HOME/.tmux.conf" "$BACKUP_DIR"
  
  echo -e "${OK} Backup completed and stored in ${BACKUP_DIR}.${RESET}"
  log_message "INFO" "Configuration backup completed"
  return 0
}