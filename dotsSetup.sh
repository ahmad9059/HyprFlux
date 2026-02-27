#!/bin/bash

set -e

# ===========================
# Color-coded status labels
# ===========================
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
OK="$(tput setaf 2)[OK]$(tput sgr0)"
NOTE="$(tput setaf 6)[NOTE]$(tput sgr0)"
ACTION="$(tput setaf 4)[ACTION]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# =========================
# REPOs
# =========================
REPO_URL="https://github.com/ahmad9059/HyprFlux.git"
REPO_URL_NVIM="https://github.com/ahmad9059/nvim"
TMUXIFIER_REPO="https://github.com/jimeh/tmuxifier.git"

# ======================================
# Paths: Repos, Waybar, nvim, Sddm, Grub
# ======================================
REPO_DIR="$HOME/HyprFlux/"
BACKUP_DIR="$HOME/dotfiles_backup"
# Waybar Paths
WAYBAR_STYLE_TARGET="$HOME/.config/waybar/style.css"
WAYBAR_LAYOUT_TARGET="$HOME/.config/waybar/config"
CUSTOM_WAYBAR_STYLE="$HOME/.config/waybar/style/Catppuccin Mocha Custom.css"
CUSTOM_WAYBAR_LAYOUT="$HOME/.config/waybar/configs/[TOP] Default Laptop"
# Neovim Paths
CONFIG_DIR="$HOME/.config/nvim"
# SDDM Theme Paths
SDDM_THEME_NAME="simple-sddm-2"
SDDM_THEME_SOURCE="$REPO_DIR/$SDDM_THEME_NAME"
SDDM_THEME_DEST="/usr/share/sddm/themes/$SDDM_THEME_NAME"
SDDM_CONF="/etc/sddm.conf"
# Grub Theme Paths
GRUB_THEME_ARCHIVE="$HOME/HyprFlux/utilities/Vimix-1080p.tar.xz"
GRUB_THEME_DIR="/tmp/vimix-grub"
# PWA(Desktop Apps)
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/apps"
BROWSER="chromium"
# Wallpapers Paths
WALLPAPER_REPO="https://github.com/ahmad9059/wallpapers-bank"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
# Plymouth Setup
THEME_DIR="$HOME/HyprFlux/utilities/hyprland-mac-style"
THEME_NAME="hyprland-mac-style"
PLYMOUTH_DIR="/usr/share/plymouth/themes"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
GRUB_CONF="/etc/default/grub"

# ===========================
# Log Details
# ===========================
mkdir -p "$HOME/installer_log"
LOG_FILE="$HOME/installer_log/boot_file.log"

# =============================
# Packages list
# =============================

# Mandatory packages
REQUIRED_PACKAGES=(foot lsd bat nvim firefox tmux yazi zoxide qt6-5compat chromium npm plymouth rclone github-cli)
YAY_REQUIRED_PACKAGES=()
# Pacman Packages (Optional)
PACMAN_PACKAGES=(
  foot alacritty lsd bat tmux neovim tldr
  obs-studio vlc yazi luacheck luarocks hyprpicker
  obsidian github-cli noto-fonts-emoji
  ttf-noto-nerd noto-fonts proton-vpn-gtk-app
)
# Yay Packages (Optional)
YAY_PACKAGES=(
  visual-studio-code-bin 64gram-desktop-bin vesktop
  foliate stacer-bin localsend-bin
)

# ===========================
# Log Details
# ===========================
LOG_FILE="$HOME/hyprflux_log/dotsSetup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ================================
# Ask for sudo once, keep it alive
# ================================
echo "${NOTE} Asking for sudo password^^...${RESET}"
sudo -v
keep_sudo_alive() {
  while true; do
    sudo -n true
    sleep 30
  done
}
keep_sudo_alive &
SUDO_KEEP_ALIVE_PID=$!

trap 'kill $SUDO_KEEP_ALIVE_PID' EXIT

# ====================
# Clone dotfiles repo
# ====================
echo -e "${ACTION} Cloning dotfiles into ${REPO_DIR}...${RESET}"

# If repo folder already exists
if [ -d "$REPO_DIR" ]; then
  echo -e "${NOTE} Folder ${REPO_DIR} already exists. Skipping clone.${RESET}"
else
  if git clone "$REPO_URL" "$REPO_DIR" &>>"$LOG_FILE"; then
    echo -e "${OK} Dotfiles cloned successfully to ${REPO_DIR}.${RESET}"
  else
    echo -e "${ERROR} Failed to clone dotfiles repo from ${REPO_URL}.${RESET}"
    exit 1
  fi
fi

# =================
# Required Packages
# =================
echo -e "${ACTION} Installing required packages...${RESET}" | tee -a "$LOG_FILE"
# Print package list with header in blue and packages in default color
echo -e "\n\033[1;34mRequired Packages:\033[0m\n" | tee -a "$LOG_FILE"
for pkg in "${REQUIRED_PACKAGES[@]}"; do
  echo -e "  • $pkg" | tee -a "$LOG_FILE"
done
echo | tee -a "$LOG_FILE"
echo -e "${ACTION} Packages Installing in Progress...${RESET}" | tee -a "$LOG_FILE"
# Enable pipefail so pacman failure is detected even with tee
set -o pipefail
MAX_RETRIES=5
COUNT=0
SUCCESS=0
# Start with all required packages as missing
MISSING_PKGS=("${REQUIRED_PACKAGES[@]}")
until [ $COUNT -ge $MAX_RETRIES ]; do
  if script -qfc "sudo pacman -Sy --noconfirm --needed ${MISSING_PKGS[*]}" /dev/null | tee -a "$LOG_FILE"; then
    # Re-check what’s still missing
    NEW_MISSING=()
    for pkg in "${MISSING_PKGS[@]}"; do
      if ! pacman -Qi "$pkg" &>/dev/null; then
        NEW_MISSING+=("$pkg")
      fi
    done
    if [ ${#NEW_MISSING[@]} -eq 0 ]; then
      SUCCESS=1
      break
    else
      MISSING_PKGS=("${NEW_MISSING[@]}")
    fi
  fi
  COUNT=$((COUNT + 1))
  echo -e "${ERROR} Some packages failed to install. Retry $COUNT/$MAX_RETRIES in 5s...${RESET}" | tee -a "$LOG_FILE"
  sleep 5
done
set +o pipefail
if [ $SUCCESS -eq 1 ]; then
  echo -e "${OK} All required packages installed successfully.${RESET}" | tee -a "$LOG_FILE"
else
  echo -e "${ERROR} Failed to install packages after $MAX_RETRIES attempts: ${MISSING_PKGS[*]}${RESET}" | tee -a "$LOG_FILE"
  exit 1
fi

# =================
# Required AUR Packages (yay)
# =================

echo -e "${ACTION} Installing required AUR packages with yay...${RESET}" | tee -a "$LOG_FILE"

# Print package list with header in blue and packages in default color
echo -e "\n\033[1;34mAUR Packages:\033[0m\n" | tee -a "$LOG_FILE"
for pkg in "${YAY_REQUIRED_PACKAGES[@]}"; do
  echo -e "  • $pkg" | tee -a "$LOG_FILE"
done
echo | tee -a "$LOG_FILE"

echo -e "${ACTION} Packages Installing in Progress...${RESET}" | tee -a "$LOG_FILE"

# Enable pipefail so yay failure is detected even with tee
set -o pipefail
MAX_RETRIES=5
COUNT=0
SUCCESS=0

# Start with all required packages as missing
MISSING_PKGS=("${YAY_REQUIRED_PACKAGES[@]}")

until [ $COUNT -ge $MAX_RETRIES ]; do
  if yay -Sy --noconfirm --needed ${MISSING_PKGS[*]} | tee -a "$LOG_FILE"; then
    # Re-check what’s still missing
    NEW_MISSING=()
    for pkg in "${MISSING_PKGS[@]}"; do
      if ! pacman -Qi "$pkg" &>/dev/null; then
        NEW_MISSING+=("$pkg")
      fi
    done
    if [ ${#NEW_MISSING[@]} -eq 0 ]; then
      SUCCESS=1
      break
    else
      MISSING_PKGS=("${NEW_MISSING[@]}")
    fi
  fi
  COUNT=$((COUNT + 1))
  echo -e "${ERROR} Some AUR packages failed to install. Retry $COUNT/$MAX_RETRIES in 5s...${RESET}" | tee -a "$LOG_FILE"
  sleep 5
done

set +o pipefail

if [ $SUCCESS -eq 1 ]; then
  echo -e "${OK} All AUR packages installed successfully with yay.${RESET}" | tee -a "$LOG_FILE"
else
  echo -e "${ERROR} Failed to install AUR packages after $MAX_RETRIES attempts: ${MISSING_PKGS[*]}${RESET}" | tee -a "$LOG_FILE"
  exit 1
fi

# ===========================
# Backup old configs
# ===========================
echo -e "${ACTION} Backing up existing dotfiles to ${BACKUP_DIR}...${RESET}"
# Remove existing backup if it exists
if [ -d "$BACKUP_DIR" ]; then
  echo -e "${ACTION} Existing backup found. Removing old backup...${RESET}"
  rm -rf "$BACKUP_DIR" &>>"$LOG_FILE"
fi
if mkdir -p "$BACKUP_DIR" &>>"$LOG_FILE"; then
  # Copy only if files/folders exist
  [ -d "$HOME/.config" ] && cp -r "$HOME/.config" "$BACKUP_DIR/" &>>"$LOG_FILE"
  [ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$BACKUP_DIR/" &>>"$LOG_FILE"
  [ -f "$HOME/.tmux.conf" ] && cp "$HOME/.tmux.conf" "$BACKUP_DIR/" &>>"$LOG_FILE"

  echo -e "${OK} Backup completed and stored in ${BACKUP_DIR}.${RESET}"
else
  echo -e "${ERROR} Failed to create backup directory at ${BACKUP_DIR}.${RESET}"
  exit 1
fi

# ========================================
# Remove old config folders before copying
# ========================================
echo -e "${ACTION} Removing old config folders from ~/.config that are in ${REPO_DIR}...${RESET}"
if [ -d "$REPO_DIR/.config" ]; then
  for folder in "$REPO_DIR/.config/"*; do
    folder_name=$(basename "$folder")
    if [ -d "$HOME/.config/$folder_name" ]; then
      rm -rf "$HOME/.config/$folder_name" &>>"$LOG_FILE"
    fi
  done
  echo -e "${OK} Old config folders removed successfully.${RESET}"
else
  echo -e "${WARN} No .config folder found in ${REPO_DIR}, skipping removal.${RESET}"
fi

# =================
# Copy new dotfiles
# =================
echo -e "${ACTION} Copying new dotfiles...${RESET}"

if [ -d "$REPO_DIR/.config" ]; then
  mkdir -p ~/.config
  {
    cp -r "$REPO_DIR/.config/"* ~/.config/
    cp "$REPO_DIR/.zshrc" ~/
    cp "$REPO_DIR/.tmux.conf" ~/
  } >>"$LOG_FILE" 2>&1

  if [ $? -eq 0 ]; then
    echo -e "${OK} HyprFlux dotfiles copied successfully.${RESET}"
  else
    echo -e "${ERROR} Failed to copy one or more dotfiles. Check $LOG_FILE for details.${RESET}"
  fi
else
  echo -e "${ERROR} '$REPO_DIR/.config' does not exist. Dotfiles not copied.${RESET}"
fi

# ==========================
# Install Neovim from GitHub
# ==========================
echo -e "${ACTION} Installing Neovim config from ${REPO_URL_NVIM}...${RESET}" | tee -a "$LOG_FILE"
if [ -d "$CONFIG_DIR" ]; then
  rm -rf "$CONFIG_DIR" >>"$LOG_FILE" 2>&1
fi
if git clone "$REPO_URL_NVIM" "$CONFIG_DIR" >>"$LOG_FILE" 2>&1; then
  echo -e "${OK} Neovim config installed in ${CONFIG_DIR}.${RESET}" | tee -a "$LOG_FILE"
else
  echo -e "${ERROR} Failed to clone Neovim config from ${REPO_URL_NVIM}.${RESET}" | tee -a "$LOG_FILE"
  exit 1
fi
echo -e "${ACTION} Installing and Setting Up Neovim Lazy, Mason Packages...${RESET}" | tee -a "$LOG_FILE"
nvim --headless -c 'qa' >>"$LOG_FILE" 2>&1
nvim --headless -c 'Lazy sync' -c 'qa' >>"$LOG_FILE" 2>&1
echo -e "${OK} NvChad, plugins, and Mason packages installed successfully!${RESET}" | tee -a "$LOG_FILE"

# =========================
# Themes
# =========================
echo -e "${ACTION} Installing themes from ${REPO_DIR}.themes...${RESET}"

if [ -d "$REPO_DIR/.themes" ]; then
  mkdir -p "$HOME/.themes" &>>"$LOG_FILE"
  cp -r "$REPO_DIR/.themes/"* "$HOME/.themes/" &>>"$LOG_FILE"
  echo -e "${OK} Themes installed successfully in ~/.themes.${RESET}"
else
  echo -e "${WARN} No .themes directory found in ${REPO_DIR}, skipping theme installation.${RESET}"
fi

# ==============================
# Icons
# ==============================
if command -v yay >/dev/null 2>&1; then
  echo -e "${ACTION} Installing 'papirus-icon-theme' via yay...${RESET}"
  if sudo pacman -S --needed --noconfirm papirus-icon-theme papirus-folders >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} 'papirus-icon-theme' installed successfully.${RESET}"

    # Set folder color to cyan for Papirus-Dark
    echo -e "${ACTION} Setting Papirus folders set to cyan (Papirus-Dark).${RESET}"
    papirus-folders -C cyan --theme Papirus-Dark &>>"$LOG_FILE"
    echo -e "${OK} Papirus folders set to cyan (Papirus-Dark).${RESET}"

    # Install custom cursor theme
    CURSOR_ARCHIVE="$HOME/HyprFlux/utilities/Future-black-cursors.tar.gz"
    ICONS_DIR="$HOME/.icons"

    mkdir -p "$ICONS_DIR"
    if tar -xzf "$CURSOR_ARCHIVE" -C "$ICONS_DIR"; then
      echo -e "${OK} Future Black cursors installed to $ICONS_DIR.${RESET}"
    else
      echo -e "${ERROR} Failed to extract Future Black cursors from $CURSOR_ARCHIVE.${RESET}"
    fi

  else
    echo -e "${ERROR} Failed to install 'papirus-icon-theme'. Check $LOG_FILE for details.${RESET}"
  fi
else
  echo -e "${WARN} yay not found. Skipping 'papirus-icon-theme' installation.${RESET}"
fi

# =============================
# Waybar style
# =============================
echo -e "${ACTION} Linking custom Waybar style...${RESET}"

if [ -f "$CUSTOM_WAYBAR_STYLE" ]; then
  ln -sf "$CUSTOM_WAYBAR_LAYOUT" "$WAYBAR_LAYOUT_TARGET" &>>"$LOG_FILE"
  ln -sf "$CUSTOM_WAYBAR_STYLE" "$WAYBAR_STYLE_TARGET" &>>"$LOG_FILE"

  if pgrep -x "waybar" &>/dev/null; then
    pkill -SIGUSR2 waybar &>>"$LOG_FILE"
    echo -e "${OK} Waybar style applied and reloaded.${RESET}"
  else
    echo -e "${WARN} Waybar not running. Style will apply on next launch.${RESET}"
  fi
else
  echo -e "${WARN} Custom Waybar style not found at ${CUSTOM_WAYBAR_STYLE}, skipping.${RESET}"
fi

# ========================
# Setting the SDDM theme
# ========================
echo -e "${ACTION} Setting SDDM theme to '$SDDM_THEME_NAME'...${RESET}"

# Install theme if source exists
if [ -d "$SDDM_THEME_SOURCE" ]; then
  sudo cp -r "$SDDM_THEME_SOURCE" "$SDDM_THEME_DEST" &>>"$LOG_FILE"
  echo -e "${OK} SDDM theme '$SDDM_THEME_NAME' installed.${RESET}"
else
  echo -e "${YELLOW} Theme folder '$SDDM_THEME_SOURCE' not found. Skipping theme installation.${RESET}"
fi

# Ensure config file exists
if [ ! -f "$SDDM_CONF" ]; then
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

# ===============
# Gtk theme setup
# ===============
echo -e "${ACTION} Updating GTK theme settings...${RESET}" | tee -a "$LOG_FILE"

{
  mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0

  gsettings set org.gnome.desktop.interface gtk-theme 'HyprFlux-Compact'
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
  gsettings set org.gnome.desktop.interface cursor-theme 'Future-black Cursors'
  gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
  gsettings set org.gnome.desktop.wm.preferences theme 'HyprFlux-Compact'

  echo -e "${OK} GTK Theme, Icon, and Cursor applied.${RESET}"
} >>"$LOG_FILE" 2>&1

if command -v nwg-look >/dev/null 2>&1; then
  echo -e "${ACTION} Exporting GTK settings to settings.ini...${RESET}" | tee -a "$LOG_FILE"
  nwg-look -x >>"$LOG_FILE" 2>&1
else
  echo -e "${WARN} nwg-look not found. Skipping export step.${RESET}" | tee -a "$LOG_FILE"
fi

# =============================
# Grub BootLoader Theme (Vimix)
# =============================
echo -e "${ACTION} Checking for GRUB...${RESET}"

if command -v grub-install >/dev/null 2>&1 || command -v grub-mkconfig >/dev/null 2>&1; then
  echo -e "${OK} GRUB detected. Installing GRUB theme (Vimix)...${RESET}"

  mkdir -p "$GRUB_THEME_DIR"
  tar -xf "$GRUB_THEME_ARCHIVE" -C "$GRUB_THEME_DIR"

  INSTALL_PATH=$(find "$GRUB_THEME_DIR" -type f -name "install.sh" -exec dirname {} \; | head -n1)
  if [ -n "$INSTALL_PATH" ]; then
    echo -e "${ACTION} Running GRUB theme installer...${RESET}"
    pushd "$INSTALL_PATH" >/dev/null
    sudo bash ./install.sh >/dev/null 2>&1
    popd >/dev/null
    echo -e "${OK} GRUB theme installed successfully.${RESET}"
  else
    echo -e "${WARN} install.sh not found in extracted Vimix theme. Skipping.${RESET}"
  fi
else
  echo -e "${WARN} GRUB not detected. Skipping GRUB theme installation.${RESET}"
fi

# ============================
# Install Plymouth and Theme Installation
# ============================
echo -e "${ACTION} Installing Plymouth...${RESET}"
if ! pacman -Qi plymouth &>/dev/null; then
  if sudo pacman -S --needed --noconfirm plymouth &>>"$LOG_FILE"; then
    echo -e "${OK} Plymouth installed successfully.${RESET}"
  else
    echo -e "${ERROR} Failed to install Plymouth.${RESET}"
    exit 1
  fi
else
  echo -e "${NOTE} Plymouth already installed.${RESET}"
fi
# Copy Plymouth Theme
if [ -d "$THEME_DIR" ]; then
  echo -e "${ACTION} Copying theme '$THEME_NAME' to $PLYMOUTH_DIR...${RESET}"
  sudo mkdir -p "$PLYMOUTH_DIR"
  sudo cp -r "$THEME_DIR" "$PLYMOUTH_DIR/" &&
    echo -e "${OK} Theme '$THEME_NAME' installed.${RESET}" ||
    {
      echo -e "${ERROR} Failed to copy theme!${RESET}"
      exit 1
    }
else
  echo -e "${ERROR} Theme directory $THEME_DIR not found!${RESET}"
  exit 1
fi
# Enable Plymouth in mkinitcpio
if grep -q "plymouth" "$MKINITCPIO_CONF"; then
  echo -e "${NOTE} Plymouth hook already present in mkinitcpio.conf.${RESET}"
else
  echo -e "${ACTION} Adding plymouth hook to mkinitcpio.conf...${RESET}"
  sudo sed -i 's/HOOKS=(/HOOKS=(plymouth /' "$MKINITCPIO_CONF"
  echo -e "${OK} Plymouth hook added to mkinitcpio.conf.${RESET}"
fi
# Set Plymouth Theme
echo -e "${ACTION} Setting Plymouth theme to '$THEME_NAME'...${RESET}"
if sudo plymouth-set-default-theme -R "$THEME_NAME" &>>"$LOG_FILE"; then
  echo -e "${OK} Plymouth theme set successfully.${RESET}"
else
  echo -e "${ERROR} Failed to set Plymouth theme.${RESET}"
  exit 1
fi
# Update GRUB / kernel params
if [ -f "$GRUB_CONF" ]; then
  echo -e "${ACTION} Ensuring 'quiet splash' are enabled in GRUB...${RESET}"
  if ! grep -q "splash" "$GRUB_CONF"; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet splash /' "$GRUB_CONF"
    sudo grub-mkconfig -o /boot/grub/grub.cfg &>>"$LOG_FILE"
    echo -e "${OK} GRUB updated with quiet splash.${RESET}"
  elif ! grep -q "quiet" "$GRUB_CONF"; then
    sudo sed -i 's/splash/quiet splash/' "$GRUB_CONF"
    sudo grub-mkconfig -o /boot/grub/grub.cfg &>>"$LOG_FILE"
    echo -e "${OK} GRUB updated to include quiet.${RESET}"
  else
    echo -e "${NOTE} 'quiet splash' already configured in GRUB.${RESET}"
  fi
else
  echo -e "${WARN} $GRUB_CONF not found. Skipping GRUB config update.${RESET}"
fi
# Rebuild initramfs
echo -e "${ACTION} Rebuilding initramfs...${RESET}"
if sudo mkinitcpio -P &>>"$LOG_FILE"; then
  echo -e "${OK} Initramfs rebuilt successfully.${RESET}"
else
  echo -e "${ERROR} Failed to rebuild initramfs.${RESET}"
  exit 1
fi
echo -e "${OK} !! Plymouth with theme '$THEME_NAME' is ready! Reboot to see it. !!${RESET}"

# ==========================
# Install Tmux and Tmuxifier
# ==========================
echo -e "${ACTION} Installing Tmux Plugin Manager (TPM) and tmuxifier...${RESET}"
TPM_DIR="$HOME/.tmux/plugins/tpm"
# Tmuxifier installation
if [ -d "$HOME/.tmuxifier" ]; then
  echo -e "${WARN} Existing ~/.tmuxifier found, removing it for a fresh install...${RESET}"
  rm -rf "$HOME/.tmuxifier"
fi
git clone "$TMUXIFIER_REPO" "$HOME/.tmuxifier"
# Show OK only once
echo -e "${OK} Official tmuxifier cloned to $HOME/.tmuxifier${RESET}"
# Copy layouts
mkdir -p "$HOME/.tmuxifier/layouts"
cp -r "$REPO_DIR/.tmuxifier/layouts/." "$HOME/.tmuxifier/layouts/"
# TPM installation
if [ -d "$TPM_DIR" ]; then
  echo -e "${WARN} TPM already installed at $TPM_DIR. Skipping clone.${RESET}"
else
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
# Install TPM plugins without opening tmux
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
  "$TPM_DIR/bin/install_plugins"
  echo -e "${OK} Tmux plugins installed via TPM${RESET}"
else
  echo -e "${ERROR} TPM install script not found at $TPM_DIR/bin/install_plugins${RESET}"
fi

# =================================================
# Remove only the first \n inside the print -P line
# =================================================

echo -e "${ACTION} Removing leading from print -P line in refined theme...${RESET}" | tee -a "$LOG_FILE"

if sed -i 's/print -P "\\n\(.*\)"/print -P "\1"/' ~/.oh-my-zsh/themes/refined.zsh-theme; then
  echo -e "${OK} Successfully removed leading from refined.zsh-theme.${RESET}" | tee -a "$LOG_FILE"
else
  echo -e "${ERROR} Failed to update refined.zsh-theme.${RESET}" | tee -a "$LOG_FILE"
  exit 1
fi

# =================
# Wallpapers Setup
# =================
echo -e "${ACTION} Updating wallpapers and Setup...${RESET}"
# Remove old wallpapers folder if exists
rm -rf "$WALLPAPER_DIR"
while true; do
  echo -e "${ACTION} Cloning wallpapers repository...${RESET}"
  if git clone --depth=1 "$WALLPAPER_REPO" "$WALLPAPER_DIR"; then
    echo -e "${OK} Wallpapers cloned successfully to $WALLPAPER_DIR${RESET}"
    break
  else
    echo -e "${WARN} Clone failed, retrying in 5 seconds...${RESET}"
    sleep 5
  fi
done

# ==============================
# Chromium Web Apps Setup
# ==============================
echo -e "${ACTION} Creating Web Apps and desktop entries...${RESET}"

mkdir -p "$DESKTOP_DIR" "$ICON_DIR"

# List of apps (Name|URL|IconName)
apps=(
  "Netflix|https://www.netflix.com|netflix"
  "WhatsApp|https://web.whatsapp.com|whatsapp"
  "ChatGPT|https://chat.openai.com|chatgpt"
  "YouTube|https://www.youtube.com|youtube"
  "GitHub|https://github.com|github"
  "Cineby|https://www.cineby.app|cineby"
  "Vercel|https://vercel.com|vercel"
  "tldraw|https://www.tldraw.com|tldraw"
  "FrontendMasters|https://frontendmasters.com|frontendmasters"
  "Spotify|https://open.spotify.com|spotify"
  "Ahmad|https://itsahmad.me|itsahmad"
  "LinkedIn|https://www.linkedin.com|linkedin"
  "X|https://x.com|x"
  "Instagram|https://www.instagram.com|instagram"
  "Chess|https://www.chess.com|chess"
  "LeetCode|https://leetcode.com|leetcode"
  "Claude|https://claude.ai|claude"
  "Grok|https://grok.com|grok"
  "Gmail|https://mail.google.com|gmail"
  "TechURLs|https://techurls.com|techurls"
  "Reddit|https://www.reddit.com|reddit"
  "Canva|https://www.canva.com|canva"
  "Figma|https://www.figma.com|figma"
  "NotebookLM|https://notebooklm.google.com|notebooklm"
  "Slack|https://slack.com|slack"
  "Microsoft365|https://www.microsoft365.com|microsoft365"
  "HyprFlux|https://hyprFlux.dev|hyprflux"
  "Scrimba|https://scrimba.com|scrimba"
)

download_icon() {
  local url="$1"
  local name="$2"
  local icon_path="$ICON_DIR/$name.png"

  if [[ -f "$icon_path" ]]; then
    echo -e "${NOTE} Icon for $name already exists. Skipping.${RESET}"
    return
  fi

  echo -e "${NOTE} Downloading icon for $name...${RESET}"

  # Try Homarr (light → dark → plain)
  for variant in "-light" "-dark" ""; do
    if curl -fsSL "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/${name}${variant}.png" -o "$icon_path" 2>>"$LOG_FILE"; then
      if file --mime-type "$icon_path" | grep -q "image/png"; then
        echo -e "${OK} Icon for $name downloaded from Homarr (${variant:-plain}).${RESET}"
        return
      else
        echo -e "${WARN} Homarr returned invalid file for $name (${variant:-plain}). Retrying...${RESET}"
        rm -f "$icon_path"
      fi
    fi
  done

  # Fallback: Google S2 favicon API
  if curl -fsSL "https://www.google.com/s2/favicons?sz=128&domain=$url" -o "$icon_path" 2>>"$LOG_FILE"; then
    if file --mime-type "$icon_path" | grep -q "image/png"; then
      echo -e "${OK} Icon for $name downloaded via Google S2.${RESET}"
      return
    else
      echo -e "${WARN} Google S2 returned invalid file for $name. Retrying...${RESET}"
      rm -f "$icon_path"
    fi
  fi

  # Fallback: direct favicon.ico from site
  if curl -fsSL "$url/favicon.ico" -o "$icon_path" 2>>"$LOG_FILE"; then
    if file --mime-type "$icon_path" | grep -q "image/"; then
      echo -e "${OK} Icon for $name downloaded directly from $url/favicon.ico.${RESET}"
      return
    else
      echo -e "${WARN} Invalid favicon from $url/favicon.ico. Skipping.${RESET}"
      rm -f "$icon_path"
    fi
  fi

  echo -e "${WARN} No icon available for $name after all fallbacks.${RESET}"
}

make_desktop_entry() {
  local name="$1"
  local url="$2"
  local icon="$3"
  local desktop_file="$DESKTOP_DIR/$icon.desktop"

  {
    echo "[Desktop Entry]"
    echo "Name=$name"
    echo "Exec=$BROWSER --new-window --ozone-platform=wayland --app=$url"
    [[ -f "$ICON_DIR/$icon.png" ]] && echo "Icon=$ICON_DIR/$icon.png"
    echo "Type=Application"
    echo "Categories=Network;WebApp;"
  } >"$desktop_file"

  if [[ -f "$desktop_file" ]]; then
    echo -e "${OK} Created desktop entry for $name.${RESET}"
  else
    echo -e "${ERROR} Failed to create desktop entry for $name.${RESET}"
  fi
}

# Main loop
for entry in "${apps[@]}"; do
  IFS="|" read -r name url icon <<<"$entry"
  download_icon "$url" "$icon"
  make_desktop_entry "$name" "$url" "$icon"
done

echo -e "${OK} All Chromium web apps created in $DESKTOP_DIR with icons in $ICON_DIR.${RESET}"

# ==========================================
# Quickshell Configuration Adjustments
# ==========================================
echo -e "${ACTION} Setting Up the QuickShell if Installed${RESET}"
# Check if quickshell is installed
if command -v qs >/dev/null 2>&1; then
  echo -e "${NOTE} QuickShell detected, adjusting configs${RESET}"
  # Uncomment exec-once line in Startup_Apps.conf
  sed -i '/^\s*#exec-once = qs/s/^#//' ~/.config/hypr/UserConfigs/Startup_Apps.conf
  # Uncomment qs refresh lines in scripts
  sed -i '/#pkill qs && qs &/s/^#//' ~/.config/hypr/scripts/RefreshNoWaybar.sh
  sed -i '/#pkill qs && qs &/s/^#//' ~/.config/hypr/scripts/Refresh.sh
  # Uncomment the quickshell keybind line
  sed -i "/^#bind = \$mainMod, A, global, quickshell:overviewToggle/s/^#//" ~/.config/hypr/UserConfigs/UserKeybinds.conf
  # Comment out the ags overview keybind if it exists
  sed -i "/^\s*bind\s*=\s*\\\$mainMod,\s*A,\s*exec,\s*pkill rofi\s*||\s*true\s*&&\s*ags\s*-t\s*'overview'/{s/^\s*/#/}" ~/.config/hypr/UserConfigs/UserKeybinds.conf
  echo -e "${OK} QuickShell Setting Completed${RESET}"
fi

# ===========================
# Install Bibata Hyprcursor
# ===========================
CURSOR_URL="https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor/releases/download/1.0/hypr_Bibata-Modern-Classic.tar.gz"
CURSOR_DIR="$HOME/.icons"
HYPR_ENV_FILE="$HOME/.config/hypr/UserConfigs/ENVariables.conf"
TARGET_DIR="$CURSOR_DIR/Bibata-Modern-Classic"

echo "${ACTION} Downloading and installing Bibata Hyprcursor...${RESET}"

mkdir -p "$CURSOR_DIR"

# Remove any old cursor folder
if [ -d "$TARGET_DIR" ]; then
  rm -rf "$TARGET_DIR"
  rm -rf "$HOME/.icons/Bibata-Modern-Ice"
  echo "${NOTE} Removed old Bibata-Modern-Classic cursor folder.${RESET}"
fi

# Download
if curl -fsSL "$CURSOR_URL" -o /tmp/hyprcursor.tar.gz; then
  echo "${OK} Cursor archive downloaded successfully.${RESET}"

  mkdir -p "$TARGET_DIR"

  if tar -xzf /tmp/hyprcursor.tar.gz -C "$TARGET_DIR"; then
    echo "${OK} Cursor extracted into $TARGET_DIR.${RESET}"

    # Update Hyprland ENVariables.conf
    if [ -f "$HYPR_ENV_FILE" ]; then
      sed -i 's/^env = HYPRCURSOR_THEME.*/env = HYPRCURSOR_THEME,Bibata-Modern-Classic/' "$HYPR_ENV_FILE"
      sed -i 's/^env = HYPRCURSOR_SIZE.*/env = HYPRCURSOR_SIZE,20/' "$HYPR_ENV_FILE"
      echo "${OK} Updated Hyprland ENVariables.conf with new cursor theme.${RESET}"
    else
      echo "${WARN} ENVariables.conf not found, creating a new one.${RESET}"
      mkdir -p "$(dirname "$HYPR_ENV_FILE")"
      {
        echo "env = HYPRCURSOR_THEME,Bibata-Modern-Classic"
        echo "env = HYPRCURSOR_SIZE,24"
      } >"$HYPR_ENV_FILE"
      echo "${OK} Created ENVariables.conf with cursor settings.${RESET}"
    fi

  else
    echo "${ERROR} Failed to extract cursor archive.${RESET}"
  fi
else
  echo "${ERROR} Failed to download cursor from $CURSOR_URL.${RESET}"
fi

# Cleanup
rm -f /tmp/hyprcursor.tar.gz

# ==============================
# Ask to install pacman packages
# ==============================
echo -e "\n${ACTION} Do you want to install the following pacman packages?${RESET}"

# Print package list with header in blue and packages in default color
echo -e "\n\033[1;34mPacman Packages (Optional):\033[0m\n" | tee -a "$LOG_FILE"
for pkg in "${PACMAN_PACKAGES[@]}"; do
  echo -e "  • $pkg" | tee -a "$LOG_FILE"
done
echo | tee -a "$LOG_FILE"

# Keep asking until valid input
while true; do
  read -rp "Type 'yes' or 'no' to continue: " ans1
  case "${ans1,,}" in # convert input to lowercase
  yes | y)
    echo -e "${ACTION} Installing pacman packages...${RESET}" | tee -a "$LOG_FILE"
    echo -e "${NOTE} Installing packages in progress...${RESET}" | tee -a "$LOG_FILE"

    # Retry logic
    MAX_RETRIES=3
    RETRY_DELAY=5
    count=0
    while [ $count -lt $MAX_RETRIES ]; do
      if sudo pacman -Sy --needed --noconfirm "${PACMAN_PACKAGES[@]}" | tee -a "$LOG_FILE"; then
        echo -e "${OK} Pacman packages installed successfully.${RESET}" | tee -a "$LOG_FILE"
        break
      else
        count=$((count + 1))
        echo -e "${WARN} Installation failed. Retry $count of $MAX_RETRIES in $RETRY_DELAY seconds...${RESET}" | tee -a "$LOG_FILE"
        sleep $RETRY_DELAY
      fi
    done

    if [ $count -eq $MAX_RETRIES ]; then
      echo -e "${ERROR} Failed to install pacman packages after $MAX_RETRIES attempts. See $LOG_FILE for details.${RESET}" | tee -a "$LOG_FILE"
      exit 1
    fi

    break
    ;;
  no | n)
    echo -e "${NOTE} Skipped installing pacman packages.${RESET}" | tee -a "$LOG_FILE"
    break
    ;;
  *)
    echo -e "${ERROR} Invalid input. Please type 'yes' or 'no'.${RESET}"
    ;;
  esac
done

# ============================
# Ask to install yay packages
# ============================

if command -v yay >/dev/null 2>&1; then
  echo -e "\n${ACTION} Do you want to install the following AUR (yay) packages?${RESET}"
  echo -e "\n\033[1;34mYay Packages:\033[0m\n" | tee -a "$LOG_FILE"
  for pkg in "${YAY_PACKAGES[@]}"; do
    echo -e "  • $pkg" | tee -a "$LOG_FILE"
  done
  echo | tee -a "$LOG_FILE"
  while true; do
    read -rp "Type 'yes' or 'no' to continue: " ans2
    case "${ans2,,}" in # convert input to lowercase
    yes | y)
      echo -e "${ACTION} Installing AUR packages...${RESET}" | tee -a "$LOG_FILE"
      echo -e "${NOTE} Installing packages in progress...${RESET}" | tee -a "$LOG_FILE"
      MAX_RETRIES=5
      RETRY_DELAY=5
      count=0
      while [ $count -lt $MAX_RETRIES ]; do
        if yay -S --needed --noconfirm --mflags "--skippgpcheck" "${YAY_PACKAGES[@]}" | tee -a "$LOG_FILE"; then
          echo -e "${OK} AUR packages installed successfully.${RESET}" | tee -a "$LOG_FILE"
          break
        else
          count=$((count + 1))
          echo -e "${WARN} Installation failed. Retry $count of $MAX_RETRIES in $RETRY_DELAY seconds...${RESET}" | tee -a "$LOG_FILE"
          sleep $RETRY_DELAY
        fi
      done
      if [ $count -eq $MAX_RETRIES ]; then
        echo -e "${ERROR} Failed to install AUR packages after $MAX_RETRIES attempts. See $LOG_FILE for details.${RESET}" | tee -a "$LOG_FILE"
        exit 1
      fi
      break
      ;;
    no | n)
      echo -e "${NOTE} Skipped installing AUR packages.${RESET}" | tee -a "$LOG_FILE"
      break
      ;;
    *)
      echo -e "${ERROR} Invalid input. Please type 'yes' or 'no'.${RESET}"
      ;;
    esac
  done
else
  echo -e "${WARN} yay is not installed. Skipping AUR packages.${RESET}" | tee -a "$LOG_FILE"
fi

echo -e "\n\n${OK} !!======= Dotfiles setup complete! =========!!${RESET}\n\n"
