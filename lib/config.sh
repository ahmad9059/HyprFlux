#!/bin/bash

# =========================
# Repository URLs
# =========================
export REPO_URL="https://github.com/ahmad9059/HyprFlux.git"
export REPO_URL_NVIM="https://github.com/ahmad9059/nvim"
export TMUXIFIER_REPO="https://github.com/jimeh/tmuxifier.git"
export WALLPAPER_REPO="https://github.com/ahmad9059/wallpapers-bank"

# ======================================
# Directory Paths
# ======================================
export REPO_DIR="$HOME/HyprFlux/"
export BACKUP_DIR="$HOME/dotfiles_backup"
export CONFIG_DIR="$HOME/.config"
export DESKTOP_DIR="$HOME/.local/share/applications"
export ICON_DIR="$HOME/.local/share/icons/apps"
export WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Waybar Paths
export WAYBAR_STYLE_TARGET="$HOME/.config/waybar/style.css"
export WAYBAR_LAYOUT_TARGET="$HOME/.config/waybar/config"
export CUSTOM_WAYBAR_STYLE="$HOME/.config/waybar/style/Catppuccin Mocha Custom.css"
export CUSTOM_WAYBAR_LAYOUT="$HOME/.config/waybar/configs/[TOP] Default Laptop"

# Neovim Paths
export NVIM_CONFIG_DIR="$HOME/.config/nvim"

# SDDM Theme Paths
export SDDM_THEME_NAME="simple-sddm-2"
export SDDM_THEME_SOURCE="$REPO_DIR/$SDDM_THEME_NAME"
export SDDM_THEME_DEST="/usr/share/sddm/themes/$SDDM_THEME_NAME"
export SDDM_CONF="/etc/sddm.conf"

# Grub Theme Paths
export GRUB_THEME_ARCHIVE="$HOME/HyprFlux/utilities/Vimix-1080p.tar.xz"
export GRUB_THEME_DIR="/tmp/vimix-grub"
export GRUB_CONF="/etc/default/grub"

# Plymouth Paths
export THEME_DIR="$HOME/HyprFlux/utilities/hyprland-mac-style"
export THEME_NAME="hyprland-mac-style"
export PLYMOUTH_DIR="/usr/share/plymouth/themes"
export MKINITCPIO_CONF="/etc/mkinitcpio.conf"

# Cursor Paths
export CURSOR_ARCHIVE="$HOME/HyprFlux/utilities/Future-black-cursors.tar.gz"
export CURSOR_URL="https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor/releases/download/1.0/hypr_Bibata-Modern-Classic.tar.gz"
export CURSOR_DIR="$HOME/.icons"
export HYPR_ENV_FILE="$HOME/.config/hypr/UserConfigs/ENVariables.conf"

# ===========================
# Application Settings
# ===========================
export BROWSER="chromium"

# ===========================
# Log Settings
# ===========================
export LOG_DIR="$HOME/hyprflux_log"
export LOG_FILE="$LOG_DIR/dotsSetup.log"

# ===========================
# Retry Settings
# ===========================
export MAX_RETRIES=5
export RETRY_DELAY=5