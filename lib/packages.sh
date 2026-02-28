#!/bin/bash
# ============================================================
# lib/packages.sh — Unified package installation with retry
# ============================================================
# Sourced by dotsSetup.sh modules. Provides:
#   - install_pacman()  — install pacman packages with retry
#   - install_yay()     — install AUR packages with retry
#   - print_pkg_list()  — display a formatted package list
# ============================================================

# Guard against double-sourcing
[[ -n "${_LIB_PACKAGES_LOADED:-}" ]] && return 0
_LIB_PACKAGES_LOADED=1

# ====== Print package list ======
# Usage: print_pkg_list "Header" "${packages[@]}"
print_pkg_list() {
  local header="$1"
  shift
  local packages=("$@")

  echo -e "\n\033[1;34m${header}:\033[0m\n"
  for pkg in "${packages[@]}"; do
    echo -e "  - $pkg"
  done
  echo
}

# ====== Install pacman packages with retry ======
# Usage: install_pacman 5 "${REQUIRED_PACKAGES[@]}"
#   $1 = max retries
#   $2+ = package names
install_pacman() {
  local max_retries="$1"
  shift
  local packages=("$@")

  # Guard: skip if no packages
  if [[ ${#packages[@]} -eq 0 ]]; then
    log_info "No pacman packages to install. Skipping."
    return 0
  fi

  log_action "Installing pacman packages..."
  print_pkg_list "Pacman Packages" "${packages[@]}"

  local count=0
  local success=0
  local missing_pkgs=("${packages[@]}")

  set -o pipefail
  until [[ $count -ge $max_retries ]]; do
    if script -qfc "sudo pacman -Sy --noconfirm --needed ${missing_pkgs[*]}" /dev/null; then
      # Re-check what is still missing
      local new_missing=()
      for pkg in "${missing_pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
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
    log_error "Some packages failed. Retry $count/$max_retries in 5s..."
    sleep 5
  done
  set +o pipefail

  if [[ $success -eq 1 ]]; then
    log_ok "All pacman packages installed successfully."
    return 0
  else
    log_error "Failed to install packages after $max_retries attempts: ${missing_pkgs[*]}"
    return 1
  fi
}

# ====== Install AUR packages with retry (yay) ======
# Usage: install_yay 5 "${YAY_PACKAGES[@]}"
#   $1 = max retries
#   $2+ = package names
install_yay() {
  local max_retries="$1"
  shift
  local packages=("$@")

  # Guard: skip if no packages
  if [[ ${#packages[@]} -eq 0 ]]; then
    log_info "No AUR packages to install. Skipping."
    return 0
  fi

  # Guard: check yay is available
  if ! command -v yay &>/dev/null; then
    log_warn "yay is not installed. Skipping AUR packages."
    return 0
  fi

  log_action "Installing AUR packages with yay..."
  print_pkg_list "AUR Packages" "${packages[@]}"

  local count=0
  local success=0
  local missing_pkgs=("${packages[@]}")

  set -o pipefail
  until [[ $count -ge $max_retries ]]; do
    if yay -Sy --noconfirm --needed "${missing_pkgs[@]}"; then
      # Re-check what is still missing
      local new_missing=()
      for pkg in "${missing_pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
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
    log_error "Some AUR packages failed. Retry $count/$max_retries in 5s..."
    sleep 5
  done
  set +o pipefail

  if [[ $success -eq 1 ]]; then
    log_ok "All AUR packages installed successfully."
    return 0
  else
    log_error "Failed to install AUR packages after $max_retries attempts: ${missing_pkgs[*]}"
    return 1
  fi
}

# ====== Install optional pacman packages (interactive) ======
# Usage: install_optional_pacman "${PACMAN_PACKAGES[@]}"
install_optional_pacman() {
  local packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi

  echo -e "\n${ACTION} Do you want to install the following pacman packages?${RESET}"
  print_pkg_list "Pacman Packages (Optional)" "${packages[@]}"

  if ask_yes_no "Install these packages?"; then
    log_action "Installing optional pacman packages..."
    if ! install_pacman 3 "${packages[@]}"; then
      log_error "Failed to install optional pacman packages."
      return 1
    fi
  else
    log_info "Skipped optional pacman packages."
  fi
}

# ====== Install optional AUR packages (interactive) ======
# Usage: install_optional_yay "${YAY_PACKAGES[@]}"
install_optional_yay() {
  local packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi

  if ! command -v yay &>/dev/null; then
    log_warn "yay is not installed. Skipping optional AUR packages."
    return 0
  fi

  echo -e "\n${ACTION} Do you want to install the following AUR (yay) packages?${RESET}"
  print_pkg_list "AUR Packages (Optional)" "${packages[@]}"

  if ask_yes_no "Install these packages?"; then
    log_action "Installing optional AUR packages..."
    if ! install_yay 5 "${packages[@]}"; then
      log_error "Failed to install optional AUR packages."
      return 1
    fi
  else
    log_info "Skipped optional AUR packages."
  fi
}
