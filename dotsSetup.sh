#!/bin/bash
# ============================================================
# dotsSetup.sh — HyprFlux dotfiles setup orchestrator
# ============================================================
# Sources shared libraries, defines config variables, then
# iterates through modules/[0-9]*.sh in sorted order.
#
# Modules are sourced (not subprocesses) so they share all
# variables and functions. Each module can be skipped via
# SKIP_MODULES env var (comma-separated).
#
# Example: SKIP_MODULES="plymouth,grub" bash dotsSetup.sh
# ============================================================

set -e

# ====== Resolve paths ======
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ====== Source shared libraries ======
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/git.sh"

# ====== Logging ======
# BUG FIX: removed dead mkdir + LOG_FILE assignment that wrote to
# $HOME/installer_log. Single tee via setup_logging — no more
# double tee (exec tee + per-command tee).
setup_logging "$HOME/hyprflux_log/dotsSetup.log"

# ====== Sudo ======
setup_sudo

# ============================================================
# Config variables — all overridable via environment
# ============================================================

# Repos
REPO_URL="${REPO_URL:-https://github.com/ahmad9059/HyprFlux.git}"
REPO_URL_NVIM="${REPO_URL_NVIM:-https://github.com/ahmad9059/nvim}"
TMUXIFIER_REPO="${TMUXIFIER_REPO:-https://github.com/jimeh/tmuxifier.git}"

# Paths
# BUG FIX: use $REPO_DIR everywhere instead of mixing $HOME/HyprFlux
REPO_DIR="${REPO_DIR:-$HOME/HyprFlux}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/dotfiles_backup}"

# Waybar
WAYBAR_STYLE_TARGET="${WAYBAR_STYLE_TARGET:-$HOME/.config/waybar/style.css}"
WAYBAR_LAYOUT_TARGET="${WAYBAR_LAYOUT_TARGET:-$HOME/.config/waybar/config}"
CUSTOM_WAYBAR_STYLE="${CUSTOM_WAYBAR_STYLE:-$HOME/.config/waybar/style/Catppuccin Mocha Custom.css}"
CUSTOM_WAYBAR_LAYOUT="${CUSTOM_WAYBAR_LAYOUT:-$HOME/.config/waybar/configs/[TOP] Default Laptop}"

# Neovim
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-$HOME/.config/nvim}"

# SDDM
SDDM_THEME_NAME="${SDDM_THEME_NAME:-simple-sddm-2}"
SDDM_THEME_SOURCE="${SDDM_THEME_SOURCE:-$REPO_DIR/$SDDM_THEME_NAME}"
SDDM_THEME_DEST="${SDDM_THEME_DEST:-/usr/share/sddm/themes/$SDDM_THEME_NAME}"
SDDM_CONF="${SDDM_CONF:-/etc/sddm.conf}"

# GRUB theme
GRUB_THEME_ARCHIVE="${GRUB_THEME_ARCHIVE:-$REPO_DIR/utilities/Vimix-1080p.tar.xz}"
GRUB_THEME_DIR="${GRUB_THEME_DIR:-/tmp/vimix-grub}"

# Web apps
DESKTOP_DIR="${DESKTOP_DIR:-$HOME/.local/share/applications}"
ICON_DIR="${ICON_DIR:-$HOME/.local/share/icons/apps}"
BROWSER="${BROWSER:-chromium}"
WEBAPPS_CONF="${WEBAPPS_CONF:-$SCRIPT_DIR/config/webapps.conf}"

# Wallpapers
WALLPAPER_REPO="${WALLPAPER_REPO:-https://github.com/ahmad9059/wallpapers-bank}"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

# Plymouth
PLYMOUTH_THEME_DIR="${PLYMOUTH_THEME_DIR:-$REPO_DIR/utilities/hyprland-mac-style}"
PLYMOUTH_THEME_NAME="${PLYMOUTH_THEME_NAME:-hyprland-mac-style}"

# Bibata cursor
# BUG FIX: cursor size unified to 24 (was 20 in sed update path, 24 in create path)
CURSOR_SIZE="${CURSOR_SIZE:-24}"
BIBATA_CURSOR_URL="${BIBATA_CURSOR_URL:-https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor/releases/download/1.0/hypr_Bibata-Modern-Classic.tar.gz}"

# GTK
GTK_THEME="${GTK_THEME:-HyprFlux-Compact}"
ICON_THEME="${ICON_THEME:-Papirus-Dark}"
CURSOR_THEME="${CURSOR_THEME:-Future-black Cursors}"
FONT_NAME="${FONT_NAME:-Adwaita Sans 11}"

# ============================================================
# Run modules in order
# ============================================================
_module_count=0
_module_failed=0

for _module_file in "$SCRIPT_DIR"/modules/[0-9]*.sh; do
  if [[ ! -f "$_module_file" ]]; then
    continue
  fi

  _module_basename="$(basename "$_module_file")"
  log_info "────────────────────────────────────────"
  log_info "Running module: $_module_basename"
  log_info "────────────────────────────────────────"

  if source "$_module_file"; then
    _module_count=$((_module_count + 1))
  else
    log_error "Module $_module_basename failed!"
    _module_failed=$((_module_failed + 1))
  fi
done

# ============================================================
# Summary
# ============================================================
echo -e "\n"
if [[ $_module_failed -eq 0 ]]; then
  log_ok "!!======= Dotfiles setup complete! ($_module_count modules ran) =========!!"
else
  log_warn "Dotfiles setup finished with $_module_failed failure(s) out of $((_module_count + _module_failed)) modules."
fi
echo -e "\n"

unset _module_count _module_failed _module_file _module_basename
