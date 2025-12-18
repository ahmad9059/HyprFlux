#!/bin/bash

# ===========================
# QuickShell Configuration Module
# ===========================

setup_quickshell() {
  print_section "Setting up QuickShell"
  
  echo -e "${ACTION} Configuring QuickShell if installed...${RESET}"
  
  # Check if quickshell is installed
  if ! command_exists qs; then
    echo -e "${NOTE} QuickShell not detected. Skipping configuration.${RESET}"
    return 0
  fi

  echo -e "${NOTE} QuickShell detected, adjusting configs...${RESET}"
  
  local startup_config="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
  local refresh_script="$HOME/.config/hypr/scripts/RefreshNoWaybar.sh"
  local refresh_waybar_script="$HOME/.config/hypr/scripts/Refresh.sh"
  local keybinds_config="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
  
  # Uncomment exec-once line in Startup_Apps.conf
  if [[ -f "$startup_config" ]]; then
    sed -i '/^\s*#exec-once = qs/s/^#//' "$startup_config"
    echo -e "${OK} Enabled QuickShell in startup configuration.${RESET}"
  fi
  
  # Uncomment qs refresh lines in scripts
  if [[ -f "$refresh_script" ]]; then
    sed -i '/#pkill qs && qs &/s/^#//' "$refresh_script"
    echo -e "${OK} Enabled QuickShell in refresh script.${RESET}"
  fi
  
  if [[ -f "$refresh_waybar_script" ]]; then
    sed -i '/#pkill qs && qs &/s/^#//' "$refresh_waybar_script"
    echo -e "${OK} Enabled QuickShell in waybar refresh script.${RESET}"
  fi
  
  # Uncomment the quickshell keybind line and comment out ags keybind
  if [[ -f "$keybinds_config" ]]; then
    # Enable QuickShell keybind
    sed -i "/^#bind = \$mainMod, A, global, quickshell:overviewToggle/s/^#//" "$keybinds_config"
    
    # Disable AGS keybind
    sed -i "/^\s*bind\s*=\s*\\\$mainMod,\s*A,\s*exec,\s*pkill rofi\s*||\s*true\s*&&\s*ags\s*-t\s*'overview'/{s/^\s*/#/}" "$keybinds_config"
    
    echo -e "${OK} Updated keybindings for QuickShell.${RESET}"
  fi
  
  echo -e "${OK} QuickShell configuration completed.${RESET}"
  log_message "INFO" "QuickShell setup completed"
  return 0
}