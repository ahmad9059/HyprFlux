#!/bin/bash

# ===========================
# Plymouth Setup Module
# ===========================

install_plymouth() {
  echo -e "${ACTION} Installing Plymouth...${RESET}"
  
  if package_installed plymouth; then
    echo -e "${NOTE} Plymouth already installed.${RESET}"
    return 0
  fi
  
  if sudo pacman -S --needed --noconfirm plymouth &>>"$LOG_FILE"; then
    echo -e "${OK} Plymouth installed successfully.${RESET}"
    return 0
  else
    echo -e "${ERROR} Failed to install Plymouth.${RESET}"
    return 1
  fi
}

install_plymouth_theme() {
  echo -e "${ACTION} Installing Plymouth theme...${RESET}"
  
  if [[ ! -d "$THEME_DIR" ]]; then
    echo -e "${ERROR} Theme directory $THEME_DIR not found!${RESET}"
    return 1
  fi
  
  echo -e "${ACTION} Copying theme '$THEME_NAME' to $PLYMOUTH_DIR...${RESET}"
  
  sudo mkdir -p "$PLYMOUTH_DIR"
  
  if sudo cp -r "$THEME_DIR" "$PLYMOUTH_DIR/" >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} Theme '$THEME_NAME' installed.${RESET}"
    return 0
  else
    echo -e "${ERROR} Failed to copy theme!${RESET}"
    return 1
  fi
}

configure_plymouth_mkinitcpio() {
  echo -e "${ACTION} Configuring Plymouth in mkinitcpio...${RESET}"
  
  if grep -q "plymouth" "$MKINITCPIO_CONF"; then
    echo -e "${NOTE} Plymouth hook already present in mkinitcpio.conf.${RESET}"
    return 0
  fi
  
  echo -e "${ACTION} Adding plymouth hook to mkinitcpio.conf...${RESET}"
  
  if sudo sed -i 's/HOOKS=(/HOOKS=(plymouth /' "$MKINITCPIO_CONF" >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} Plymouth hook added to mkinitcpio.conf.${RESET}"
    return 0
  else
    echo -e "${ERROR} Failed to add Plymouth hook to mkinitcpio.conf.${RESET}"
    return 1
  fi
}

set_plymouth_theme() {
  echo -e "${ACTION} Setting Plymouth theme to '$THEME_NAME'...${RESET}"
  
  if sudo plymouth-set-default-theme -R "$THEME_NAME" &>>"$LOG_FILE"; then
    echo -e "${OK} Plymouth theme set successfully.${RESET}"
    return 0
  else
    echo -e "${ERROR} Failed to set Plymouth theme.${RESET}"
    return 1
  fi
}

configure_grub_for_plymouth() {
  echo -e "${ACTION} Configuring GRUB for Plymouth...${RESET}"
  
  if [[ ! -f "$GRUB_CONF" ]]; then
    echo -e "${WARN} $GRUB_CONF not found. Skipping GRUB config update.${RESET}"
    return 0
  fi
  
  echo -e "${ACTION} Ensuring 'quiet splash' are enabled in GRUB...${RESET}"
  
  local grub_updated=false
  
  if ! grep -q "splash" "$GRUB_CONF"; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet splash /' "$GRUB_CONF"
    grub_updated=true
    echo -e "${OK} Added 'quiet splash' to GRUB configuration.${RESET}"
  elif ! grep -q "quiet" "$GRUB_CONF"; then
    sudo sed -i 's/splash/quiet splash/' "$GRUB_CONF"
    grub_updated=true
    echo -e "${OK} Added 'quiet' to GRUB configuration.${RESET}"
  else
    echo -e "${NOTE} 'quiet splash' already configured in GRUB.${RESET}"
  fi
  
  if [[ "$grub_updated" == true ]]; then
    if sudo grub-mkconfig -o /boot/grub/grub.cfg &>>"$LOG_FILE"; then
      echo -e "${OK} GRUB configuration updated.${RESET}"
    else
      echo -e "${ERROR} Failed to update GRUB configuration.${RESET}"
      return 1
    fi
  fi
  
  return 0
}

rebuild_initramfs() {
  echo -e "${ACTION} Rebuilding initramfs...${RESET}"
  
  if sudo mkinitcpio -P &>>"$LOG_FILE"; then
    echo -e "${OK} Initramfs rebuilt successfully.${RESET}"
    return 0
  else
    echo -e "${ERROR} Failed to rebuild initramfs.${RESET}"
    return 1
  fi
}

setup_plymouth() {
  print_section "Setting up Plymouth Boot Screen"
  
  # Install Plymouth
  install_plymouth || return 1
  
  # Install Plymouth theme
  install_plymouth_theme || return 1
  
  # Configure mkinitcpio
  configure_plymouth_mkinitcpio || return 1
  
  # Set Plymouth theme
  set_plymouth_theme || return 1
  
  # Configure GRUB
  configure_grub_for_plymouth || return 1
  
  # Rebuild initramfs
  rebuild_initramfs || return 1
  
  echo -e "${OK} Plymouth with theme '$THEME_NAME' is ready! Reboot to see it.${RESET}"
  log_message "INFO" "Plymouth setup completed"
  return 0
}