#!/bin/bash

# ===========================
# Waybar Configuration Module
# ===========================

setup_waybar() {
  print_section "Setting up Waybar"
  
  echo -e "${ACTION} Linking custom Waybar style...${RESET}"

  if [[ ! -f "$CUSTOM_WAYBAR_STYLE" ]]; then
    echo -e "${WARN} Custom Waybar style not found at ${CUSTOM_WAYBAR_STYLE}, skipping.${RESET}"
    return 0
  fi

  # Create symbolic links
  if ln -sf "$CUSTOM_WAYBAR_LAYOUT" "$WAYBAR_LAYOUT_TARGET" &>>"$LOG_FILE" &&
     ln -sf "$CUSTOM_WAYBAR_STYLE" "$WAYBAR_STYLE_TARGET" &>>"$LOG_FILE"; then
    
    echo -e "${OK} Waybar configuration linked successfully.${RESET}"
    
    # Reload waybar if it's running
    if pgrep -x "waybar" &>/dev/null; then
      pkill -SIGUSR2 waybar &>>"$LOG_FILE"
      echo -e "${OK} Waybar style applied and reloaded.${RESET}"
    else
      echo -e "${WARN} Waybar not running. Style will apply on next launch.${RESET}"
    fi
    
    log_message "INFO" "Waybar configuration completed"
    return 0
  else
    echo -e "${ERROR} Failed to link Waybar configuration files.${RESET}"
    log_message "ERROR" "Waybar configuration failed"
    return 1
  fi
}