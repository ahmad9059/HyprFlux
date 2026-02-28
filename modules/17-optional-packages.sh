#!/bin/bash
# ============================================================
# modules/17-optional-packages.sh — Interactive optional packages
# ============================================================
should_skip "optional-packages" && return 0

# ====== Pacman optional packages ======
PACMAN_PACKAGES=(
  foot alacritty lsd bat tmux neovim tldr
  obs-studio vlc yazi luacheck luarocks hyprpicker
  obsidian github-cli noto-fonts-emoji
  ttf-noto-nerd noto-fonts proton-vpn-gtk-app
)

install_optional_pacman "${PACMAN_PACKAGES[@]}"

# ====== AUR optional packages ======
YAY_PACKAGES=(
  visual-studio-code-bin 64gram-desktop-bin vesktop
  foliate stacer-bin localsend-bin
)

install_optional_yay "${YAY_PACKAGES[@]}"
