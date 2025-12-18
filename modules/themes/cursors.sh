#!/bin/bash

# ===========================
# Cursor Theme Setup Module
# ===========================

install_future_black_cursors() {
  echo -e "${ACTION} Installing Future Black cursors...${RESET}"
  
  if [[ ! -f "$CURSOR_ARCHIVE" ]]; then
    echo -e "${WARN} Future Black cursor archive not found at $CURSOR_ARCHIVE. Skipping.${RESET}"
    return 0
  fi

  ensure_dir "$CURSOR_DIR"
  
  if tar -xzf "$CURSOR_ARCHIVE" -C "$CURSOR_DIR" >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} Future Black cursors installed to $CURSOR_DIR.${RESET}"
    return 0
  else
    echo -e "${ERROR} Failed to extract Future Black cursors from $CURSOR_ARCHIVE.${RESET}"
    return 1
  fi
}

install_bibata_hyprcursor() {
  echo -e "${ACTION} Installing Bibata Hyprcursor...${RESET}"
  
  local target_dir="$CURSOR_DIR/Bibata-Modern-Classic"
  local temp_file="/tmp/hyprcursor.tar.gz"

  # Remove any old cursor folder
  if [[ -d "$target_dir" ]]; then
    rm -rf "$target_dir"
    rm -rf "$HOME/.icons/Bibata-Modern-Ice"
    echo -e "${NOTE} Removed old Bibata-Modern-Classic cursor folder.${RESET}"
  fi

  # Download cursor
  if curl -fsSL "$CURSOR_URL" -o "$temp_file" >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} Cursor archive downloaded successfully.${RESET}"

    ensure_dir "$target_dir"

    if tar -xzf "$temp_file" -C "$target_dir" >>"$LOG_FILE" 2>&1; then
      echo -e "${OK} Cursor extracted into $target_dir.${RESET}"

      # Update Hyprland ENVariables.conf
      if [[ -f "$HYPR_ENV_FILE" ]]; then
        sed -i 's/^env = HYPRCURSOR_THEME.*/env = HYPRCURSOR_THEME,Bibata-Modern-Classic/' "$HYPR_ENV_FILE"
        sed -i 's/^env = HYPRCURSOR_SIZE.*/env = HYPRCURSOR_SIZE,20/' "$HYPR_ENV_FILE"
        echo -e "${OK} Updated Hyprland ENVariables.conf with new cursor theme.${RESET}"
      else
        echo -e "${WARN} ENVariables.conf not found, creating a new one.${RESET}"
        ensure_dir "$(dirname "$HYPR_ENV_FILE")"
        {
          echo "env = HYPRCURSOR_THEME,Bibata-Modern-Classic"
          echo "env = HYPRCURSOR_SIZE,24"
        } >"$HYPR_ENV_FILE"
        echo -e "${OK} Created ENVariables.conf with cursor settings.${RESET}"
      fi

      # Cleanup
      rm -f "$temp_file"
      return 0
    else
      echo -e "${ERROR} Failed to extract cursor archive.${RESET}"
      rm -f "$temp_file"
      return 1
    fi
  else
    echo -e "${ERROR} Failed to download cursor from $CURSOR_URL.${RESET}"
    return 1
  fi
}

setup_cursor_themes() {
  print_section "Setting up Cursor Themes"
  
  # Install Future Black cursors (legacy)
  install_future_black_cursors
  
  # Install Bibata Hyprcursor (modern)
  install_bibata_hyprcursor
  
  log_message "INFO" "Cursor themes setup completed"
  return 0
}