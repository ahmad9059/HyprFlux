#!/bin/bash
# ============================================================
# HyprFlux - Zsh and Oh My Zsh Installation Script
# https://github.com/ahmad9059/HyprFlux
# ============================================================
# Based on JaKooLit's zsh script with sudo chsh workaround
# for non-interactive installation

zsh_pkg=(
  lsd
  mercurial
  zsh
  zsh-completions
)

zsh_pkg2=(
  fzf
)

# Get the current username
USER_NAME=$(whoami)

# Temporary sudoers line for passwordless chsh
SUDO_LINE="$USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/chsh # TEMP-CHSH-ALLOW"

# Function to clean up sudoers on exit
cleanup_sudoers() {
  echo "[HyprFlux] Cleaning up temporary sudoers entry..."
  sudo sed -i '/# TEMP-CHSH-ALLOW/d' /etc/sudoers 2>/dev/null || true
}
trap cleanup_sudoers EXIT

# Add temporary sudoers entry if not already present
if ! sudo grep -qF "$SUDO_LINE" /etc/sudoers 2>/dev/null; then
  echo "[HyprFlux] Adding temporary sudoers entry for $USER_NAME..."
  echo "$SUDO_LINE" | sudo tee -a /etc/sudoers >/dev/null
fi

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || {
  echo "[HyprFlux] [ERROR] Failed to change directory to $PARENT_DIR"
  exit 1
}

# Source the global functions script
if ! source "$SCRIPT_DIR/Global_functions.sh"; then
  echo "[HyprFlux] [ERROR] Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_zsh.log"

# Installing core zsh packages
printf "\n%s - [HyprFlux] Installing ${SKY_BLUE}zsh packages${RESET} .... \n" "${NOTE}"
for ZSH in "${zsh_pkg[@]}"; do
  install_package "$ZSH" "$LOG"
done

# Check if the zsh-completions directory exists
if [ -d "zsh-completions" ]; then
  rm -rf zsh-completions
fi

# Install Oh My Zsh, plugins, and set zsh as default shell
if command -v zsh >/dev/null; then
  printf "${NOTE} [HyprFlux] Installing ${SKY_BLUE}Oh My Zsh and plugins${RESET} ...\n"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended
  else
    echo "${INFO} [HyprFlux] Directory .oh-my-zsh already exists. Skipping re-installation." 2>&1 | tee -a "$LOG"
  fi

  # Check if the directories exist before cloning the repositories
  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  else
    echo "${INFO} [HyprFlux] Directory zsh-autosuggestions already exists. Skipping." 2>&1 | tee -a "$LOG"
  fi

  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  else
    echo "${INFO} [HyprFlux] Directory zsh-syntax-highlighting already exists. Skipping." 2>&1 | tee -a "$LOG"
  fi

  # Check if ~/.zshrc and .zprofile exists, create a backup, and copy the new configuration
  if [ -f "$HOME/.zshrc" ]; then
    cp -b "$HOME/.zshrc" "$HOME/.zshrc-backup" || true
  fi

  if [ -f "$HOME/.zprofile" ]; then
    cp -b "$HOME/.zprofile" "$HOME/.zprofile-backup" || true
  fi

  # Copying the preconfigured zsh themes and profile
  cp -r 'assets/.zshrc' ~/
  cp -r 'assets/.zprofile' ~/

  # Check if the current shell is zsh
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "zsh" ]; then
    printf "${NOTE} [HyprFlux] Changing default shell to ${MAGENTA}zsh${RESET}...\n"
    printf "\n%.0s" {1..2}

    # Use sudo chsh (with temporary sudoers entry) for non-interactive shell change
    if sudo chsh -s "$(command -v zsh)" "$USER_NAME"; then
      printf "${INFO} [HyprFlux] Shell changed successfully to ${MAGENTA}zsh${RESET}\n" 2>&1 | tee -a "$LOG"
    else
      echo "${ERROR} [HyprFlux] Failed to change shell. Will retry..." 2>&1 | tee -a "$LOG"
      # Retry loop as fallback
      while ! sudo chsh -s "$(command -v zsh)" "$USER_NAME"; do
        echo "${ERROR} [HyprFlux] Failed to change shell. Retrying..." 2>&1 | tee -a "$LOG"
        sleep 1
      done
      printf "${INFO} [HyprFlux] Shell changed successfully to ${MAGENTA}zsh${RESET}\n" 2>&1 | tee -a "$LOG"
    fi
  else
    echo "${NOTE} [HyprFlux] Your shell is already set to ${MAGENTA}zsh${RESET}."
  fi
fi

# Installing fzf
printf "\n%s - [HyprFlux] Installing ${SKY_BLUE}fzf${RESET} .... \n" "${NOTE}"
for ZSH2 in "${zsh_pkg2[@]}"; do
  install_package "$ZSH2" "$LOG"
done

# copy additional oh-my-zsh themes from assets
if [ -d "$HOME/.oh-my-zsh/themes" ]; then
  cp -r assets/add_zsh_theme/* ~/.oh-my-zsh/themes >>"$LOG" 2>&1
fi

printf "\n%.0s" {1..2}
echo "${OK} [HyprFlux] Zsh installation complete!"
