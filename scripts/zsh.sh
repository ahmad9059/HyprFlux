#!/bin/bash
# ============================================================
# HyprFlux - Zsh and Oh My Zsh Installation Script
# https://github.com/ahmad9059/HyprFlux
# ============================================================
# Based on HyprFlux zsh script with sudo chsh workaround
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

# Temporary sudoers drop-in for passwordless chsh/usermod.
# Using a drop-in file (not appending to /etc/sudoers) is safer — a bad line
# can't corrupt the main sudoers file, and cleanup is a simple rm.
SUDOERS_DROPIN="/etc/sudoers.d/99-hyprflux-temp"
SUDOERS_LINE="$USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/chsh, /usr/sbin/usermod # TEMP-CHSH-ALLOW"

# Function to clean up sudoers on exit (non-fatal, never hangs the shell)
cleanup_sudoers() {
  echo "[HyprFlux] Cleaning up temporary sudoers drop-in..."
  sudo -n rm -f "$SUDOERS_DROPIN" 2>/dev/null || rm -f "$SUDOERS_DROPIN" 2>/dev/null || true
}
trap cleanup_sudoers EXIT

# Create the drop-in (mode 440 required by sudo; overwrite = idempotent)
if ! sudo test -f "$SUDOERS_DROPIN"; then
  echo "[HyprFlux] Adding temporary sudoers drop-in for $USER_NAME..."
  echo "$SUDOERS_LINE" | sudo tee "$SUDOERS_DROPIN" >/dev/null
  sudo chmod 440 "$SUDOERS_DROPIN"
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

# Installing core zsh packages. All are in the extra repo, so fall back to
# pacman if the AUR helper (yay/paru) is unavailable — the shell setup must
# never depend on AUR build success.
_install_any() {  # $1=pkg, $2=log
  local _pkg="$1" _log="$2"
  if command -v "$_pkg" >/dev/null 2>&1 || pacman -Qi "$_pkg" >/dev/null 2>&1; then
    return 0
  fi
  install_package "$_pkg" "$_log" 2>/dev/null || true
  if ! command -v "$_pkg" >/dev/null 2>&1 && ! pacman -Qi "$_pkg" >/dev/null 2>&1; then
    echo "${INFO} [HyprFlux] Installing $_pkg via pacman (AUR helper unavailable)..." 2>&1 | tee -a "$_log"
    sudo pacman -S --noconfirm --needed "$_pkg" 2>&1 | tee -a "$_log"
  fi
}

printf "\n%s - [HyprFlux] Installing ${SKY_BLUE}zsh packages${RESET} .... \n" "${NOTE}"
for ZSH in "${zsh_pkg[@]}"; do
  _install_any "$ZSH" "$LOG"
done

# Installing fzf BEFORE .zshrc is copied (the .zshrc sources fzf at startup).
printf "\n%s - [HyprFlux] Installing ${SKY_BLUE}fzf${RESET} .... \n" "${NOTE}"
for ZSH2 in "${zsh_pkg2[@]}"; do
  _install_any "$ZSH2" "$LOG"
done
unset -f _install_any

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

    # chsh rejects shells that are not listed in /etc/shells — add zsh first.
    _zsh_path="$(command -v zsh)"
    if [ -n "$_zsh_path" ] && ! grep -qx "$_zsh_path" /etc/shells 2>/dev/null; then
      echo "$_zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Use sudo chsh (with temporary sudoers entry) for non-interactive shell change
    # Cap retries: 5 attempts, then warn (shell can be changed manually).
    # NOTE: no 'local' here — top-level scope; 'local' outside a function
    # errors and leaves the counter unset.
    _chsh_attempts=0
    until sudo chsh -s "$_zsh_path" "$USER_NAME"; do
      _chsh_attempts=$((_chsh_attempts + 1))
      if [ "$_chsh_attempts" -ge 5 ]; then
        echo "${WARN} [HyprFlux] chsh failed after 5 attempts — trying usermod fallback..." 2>&1 | tee -a "$LOG"
        if sudo usermod -s "$_zsh_path" "$USER_NAME"; then
          echo "${OK} [HyprFlux] Shell changed to zsh via usermod." 2>&1 | tee -a "$LOG"
          _chsh_attempts=0
        else
          echo "${ERROR} [HyprFlux] Failed to change shell. Run manually: sudo chsh -s \"$_zsh_path\" $USER_NAME" 2>&1 | tee -a "$LOG"
        fi
        break
      fi
      echo "${ERROR} [HyprFlux] Failed to change shell. Retrying ($_chsh_attempts/5)..." 2>&1 | tee -a "$LOG"
      sleep 1
    done
    if [ "$_chsh_attempts" -lt 5 ]; then
      printf "${INFO} [HyprFlux] Shell changed successfully to ${MAGENTA}zsh${RESET}\n" 2>&1 | tee -a "$LOG"
    fi
  else
    echo "${NOTE} [HyprFlux] Your shell is already set to ${MAGENTA}zsh${RESET}."
  fi
fi

# copy additional oh-my-zsh themes from assets
if [ -d "$HOME/.oh-my-zsh/themes" ]; then
  cp -r assets/add_zsh_theme/* ~/.oh-my-zsh/themes >>"$LOG" 2>&1
fi

printf "\n%.0s" {1..2}
echo "${OK} [HyprFlux] Zsh installation complete!"
