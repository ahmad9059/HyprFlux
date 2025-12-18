#!/bin/bash

# ===========================
# SDDM Theme Setup Module
# ===========================

setup_sddm_theme() {
  print_section "Setting up SDDM Theme"
  
  echo -e "${ACTION} Setting SDDM theme to '$SDDM_THEME_NAME'...${RESET}"

  # Install theme if source exists
  if [[ -d "$SDDM_THEME_SOURCE" ]]; then
    if sudo cp -r "$SDDM_THEME_SOURCE" "$SDDM_THEME_DEST" &>>"$LOG_FILE"; then
      echo -e "${OK} SDDM theme '$SDDM_THEME_NAME' installed.${RESET}"
    else
      echo -e "${ERROR} Failed to install SDDM theme.${RESET}"
      log_message "ERROR" "SDDM theme installation failed"
      return 1
    fi
  else
    echo -e "${YELLOW} Theme folder '$SDDM_THEME_SOURCE' not found. Skipping theme installation.${RESET}"
  fi

  # Ensure config file exists
  if [[ ! -f "$SDDM_CONF" ]]; then
    echo -e "${WARN} '$SDDM_CONF' not found. Creating it...${RESET}"
    echo "[Theme]" | sudo tee "$SDDM_CONF" &>>"$LOG_FILE"
  fi

  # Update or add Current= line
  if grep -q "^\[Theme\]" "$SDDM_CONF"; then
    sudo sed -i "/^\[Theme\]/,/^\[/ s/^Current=.*/Current=$SDDM_THEME_NAME/" "$SDDM_CONF" &>>"$LOG_FILE"
    if ! grep -q "^Current=" "$SDDM_CONF"; then
      sudo sed -i "/^\[Theme\]/a Current=$SDDM_THEME_NAME" "$SDDM_CONF" &>>"$LOG_FILE"
    fi
  else
    echo -e "\n[Theme]\nCurrent=$SDDM_THEME_NAME" | sudo tee -a "$SDDM_CONF" &>>"$LOG_FILE"
  fi

  echo -e "${OK} SDDM theme successfully set to '$SDDM_THEME_NAME'.${RESET}"
  log_message "INFO" "SDDM theme setup completed"
  return 0
}