#!/bin/bash
# ============================================================
# modules/03-packages.sh — Install required packages
# ============================================================
should_skip "packages" && return 0

# ====== Required pacman packages ======
# BUG FIX: 'nvim' is not a valid pacman package name; it's 'neovim'
REQUIRED_PACKAGES=(
  foot lsd bat neovim firefox tmux yazi zoxide
  qt6-5compat chromium npm plymouth rclone github-cli
)

install_pacman 5 "${REQUIRED_PACKAGES[@]}"

# ====== Required AUR packages ======
# NOTE: This array was empty in the original. Kept as a placeholder
# for future use. The empty-array guard in install_yay() prevents
# the useless retry loop that previously ran here.
YAY_REQUIRED_PACKAGES=()

install_yay 5 "${YAY_REQUIRED_PACKAGES[@]}"
