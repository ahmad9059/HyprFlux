#!/bin/bash

# ===========================
# Package Management Module
# ===========================

# Source package configuration
load_package_config() {
  local script_dir="$(get_script_dir)"
  source "$script_dir/config/packages.conf"
}

# Install required packages with retry logic
install_required_packages() {
  print_section "Installing Required Packages"
  
  load_package_config
  
  print_package_list "Required Packages" "${REQUIRED_PACKAGES[@]}"
  echo -e "${ACTION} Installing required packages...${RESET}"
  
  # Enable pipefail for proper error detection
  set -o pipefail
  
  local missing_pkgs=("${REQUIRED_PACKAGES[@]}")
  local count=0
  local success=0
  
  until [[ $count -ge $MAX_RETRIES ]]; do
    if script -qfc "sudo pacman -Sy --noconfirm --needed ${missing_pkgs[*]}" /dev/null | tee -a "$LOG_FILE"; then
      # Re-check what's still missing
      local new_missing=()
      for pkg in "${missing_pkgs[@]}"; do
        if ! package_installed "$pkg"; then
          new_missing+=("$pkg")
        fi
      done
      
      if [[ ${#new_missing[@]} -eq 0 ]]; then
        success=1
        break
      else
        missing_pkgs=("${new_missing[@]}")
      fi
    fi
    
    count=$((count + 1))
    echo -e "${ERROR} Some packages failed to install. Retry $count/$MAX_RETRIES in ${RETRY_DELAY}s...${RESET}"
    sleep $RETRY_DELAY
  done
  
  set +o pipefail
  
  if [[ $success -eq 1 ]]; then
    echo -e "${OK} All required packages installed successfully.${RESET}"
    log_message "INFO" "Required packages installation completed"
    return 0
  else
    echo -e "${ERROR} Failed to install packages after $MAX_RETRIES attempts: ${missing_pkgs[*]}${RESET}"
    log_message "ERROR" "Required packages installation failed"
    return 1
  fi
}

# Install required AUR packages
install_required_aur_packages() {
  print_section "Installing Required AUR Packages"
  
  load_package_config
  
  if [[ ${#YAY_REQUIRED_PACKAGES[@]} -eq 0 ]]; then
    echo -e "${NOTE} No required AUR packages to install.${RESET}"
    return 0
  fi
  
  if ! command_exists yay; then
    echo -e "${ERROR} yay is not installed. Cannot install AUR packages.${RESET}"
    return 1
  fi
  
  print_package_list "Required AUR Packages" "${YAY_REQUIRED_PACKAGES[@]}"
  echo -e "${ACTION} Installing required AUR packages...${RESET}"
  
  set -o pipefail
  
  local missing_pkgs=("${YAY_REQUIRED_PACKAGES[@]}")
  local count=0
  local success=0
  
  until [[ $count -ge $MAX_RETRIES ]]; do
    if yay -Sy --noconfirm --needed ${missing_pkgs[*]} | tee -a "$LOG_FILE"; then
      # Re-check what's still missing
      local new_missing=()
      for pkg in "${missing_pkgs[@]}"; do
        if ! package_installed "$pkg"; then
          new_missing+=("$pkg")
        fi
      done
      
      if [[ ${#new_missing[@]} -eq 0 ]]; then
        success=1
        break
      else
        missing_pkgs=("${new_missing[@]}")
      fi
    fi
    
    count=$((count + 1))
    echo -e "${ERROR} Some AUR packages failed to install. Retry $count/$MAX_RETRIES in ${RETRY_DELAY}s...${RESET}"
    sleep $RETRY_DELAY
  done
  
  set +o pipefail
  
  if [[ $success -eq 1 ]]; then
    echo -e "${OK} All required AUR packages installed successfully.${RESET}"
    log_message "INFO" "Required AUR packages installation completed"
    return 0
  else
    echo -e "${ERROR} Failed to install AUR packages after $MAX_RETRIES attempts: ${missing_pkgs[*]}${RESET}"
    log_message "ERROR" "Required AUR packages installation failed"
    return 1
  fi
}

# Install optional packages (interactive)
install_optional_packages() {
  print_section "Optional Package Installation"
  
  load_package_config
  
  # Ask for pacman packages
  echo -e "\n${ACTION} Do you want to install the following pacman packages?${RESET}"
  print_package_list "Pacman Packages (Optional)" "${PACMAN_PACKAGES[@]}"
  
  if ask_yes_no "Install optional pacman packages?"; then
    echo -e "${ACTION} Installing optional pacman packages...${RESET}"
    
    if retry_with_backoff 3 5 "sudo pacman -Sy --needed --noconfirm ${PACMAN_PACKAGES[*]}"; then
      echo -e "${OK} Optional pacman packages installed successfully.${RESET}"
      log_message "INFO" "Optional pacman packages installation completed"
    else
      echo -e "${ERROR} Failed to install optional pacman packages.${RESET}"
      log_message "ERROR" "Optional pacman packages installation failed"
    fi
  else
    echo -e "${NOTE} Skipped installing optional pacman packages.${RESET}"
  fi
  
  # Ask for AUR packages
  if command_exists yay; then
    echo -e "\n${ACTION} Do you want to install the following AUR (yay) packages?${RESET}"
    print_package_list "AUR Packages (Optional)" "${YAY_PACKAGES[@]}"
    
    if ask_yes_no "Install optional AUR packages?"; then
      echo -e "${ACTION} Installing optional AUR packages...${RESET}"
      
      if retry_with_backoff 5 5 "yay -S --needed --noconfirm --mflags '--skippgpcheck' ${YAY_PACKAGES[*]}"; then
        echo -e "${OK} Optional AUR packages installed successfully.${RESET}"
        log_message "INFO" "Optional AUR packages installation completed"
      else
        echo -e "${ERROR} Failed to install optional AUR packages.${RESET}"
        log_message "ERROR" "Optional AUR packages installation failed"
      fi
    else
      echo -e "${NOTE} Skipped installing optional AUR packages.${RESET}"
    fi
  else
    echo -e "${WARN} yay is not installed. Skipping optional AUR packages.${RESET}"
  fi
}