#!/bin/bash
# ============================================================
# modules/09-grub.sh — GRUB HyprFlux theme installation
# ============================================================
should_skip "grub" && return 0

log_action "Checking for GRUB..."

if command -v grub-install &>/dev/null || command -v grub-mkconfig &>/dev/null; then
  log_ok "GRUB detected. Installing HyprFlux GRUB theme..."

  _grub_theme_dir="/tmp/hyprflux-grub"
  mkdir -p "$_grub_theme_dir"

  if [[ -f "$GRUB_THEME_ARCHIVE" ]]; then
    tar -xf "$GRUB_THEME_ARCHIVE" -C "$_grub_theme_dir"

    _install_path="$(find "$_grub_theme_dir" -type f -name "install.sh" -exec dirname {} \; | head -n1)"

    if [[ -n "$_install_path" ]]; then
      log_action "Running HyprFlux GRUB theme installer..."
      pushd "$_install_path" >/dev/null
      sudo bash ./install.sh >/dev/null 2>&1 || true
      popd >/dev/null
      log_ok "HyprFlux GRUB theme installed successfully."
    else
      log_warn "install.sh not found in extracted HyprFlux theme. Skipping."
    fi
  else
    log_warn "GRUB theme archive not found at $GRUB_THEME_ARCHIVE. Skipping."
  fi

  unset _grub_theme_dir _install_path
else
  log_warn "GRUB not detected. Skipping GRUB theme installation."
fi
