#!/bin/bash

# ===========================
# GTK Theme Setup Module
# ===========================

install_themes() {
  print_section "Installing GTK Themes"
  
  echo -e "${ACTION} Installing themes from ${REPO_DIR}.themes...${RESET}"

  if [[ ! -d "$REPO_DIR/.themes" ]]; then
    echo -e "${WARN} No .themes directory found in ${REPO_DIR}, skipping theme installation.${RESET}"
    return 0
  fi

  ensure_dir "$HOME/.themes"
  
  if cp -r "$REPO_DIR/.themes/"* "$HOME/.themes/" &>>"$LOG_FILE"; then
    echo -e "${OK} Themes installed successfully in ~/.themes.${RESET}"
    log_message "INFO" "GTK themes installed"
  else
    echo -e "${ERROR} Failed to install themes.${RESET}"
    log_message "ERROR" "GTK themes installation failed"
    return 1
  fi
  
  return 0
}

configure_gtk_theme() {
  print_section "Configuring GTK Theme"
  
  echo -e "${ACTION} Updating GTK theme settings...${RESET}"

  {
    ensure_dir "$HOME/.config/gtk-3.0"
    ensure_dir "$HOME/.config/gtk-4.0"

    gsettings set org.gnome.desktop.interface gtk-theme 'Material-DeepOcean-BL'
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'Future-black Cursors'
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
    gsettings set org.gnome.desktop.wm.preferences theme 'Material-DeepOcean-BL'

    echo -e "${OK} GTK Theme, Icon, and Cursor applied.${RESET}"
  } >>"$LOG_FILE" 2>&1

  # Export GTK settings if nwg-look is available
  if command_exists nwg-look; then
    echo -e "${ACTION} Exporting GTK settings to settings.ini...${RESET}"
    nwg-look -x >>"$LOG_FILE" 2>&1
    echo -e "${OK} GTK settings exported.${RESET}"
  else
    echo -e "${WARN} nwg-look not found. Skipping export step.${RESET}"
  fi
  
  log_message "INFO" "GTK theme configuration completed"
  return 0
}

setup_gtk_themes() {
  install_themes || return 1
  configure_gtk_theme || return 1
  return 0
}