#!/bin/bash
# ============================================================
# modules/03-packages.sh — Install required packages
# ============================================================
should_skip "packages" && return 0

# ====== Required pacman packages ======
REQUIRED_PACKAGES=(
  foot lsd bat neovim firefox tmux yazi zoxide
  qt6-5compat chromium npm plymouth rclone lazygit github-cli
  networkmanager power-profiles-daemon
)

install_pacman 5 "${REQUIRED_PACKAGES[@]}"

# ====== Required AUR packages ======
# awww-git: animated wallpaper daemon (started by startup-apps.lua as
# `awww-daemon`; used by WallpaperAwww.sh / WallpaperRandom.sh /
# WallpaperSelect.sh / WallpaperAutoChange.sh)
# mpvpaper:  video wallpaper support (WallpaperSelect.sh)
YAY_REQUIRED_PACKAGES=(awww-git mpvpaper waybar-git)

install_yay 5 "${YAY_REQUIRED_PACKAGES[@]}"
