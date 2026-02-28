#!/bin/bash
# ============================================================
# modules/09-grub.sh — GRUB Vimix theme installation
# ============================================================
should_skip "grub" && return 0

log_action "Checking for GRUB..."

if command -v grub-install &>/dev/null || command -v grub-mkconfig &>/dev/null; then
  log_ok "GRUB detected. Installing GRUB theme (Vimix)..."

  _grub_theme_dir="/tmp/vimix-grub"
  mkdir -p "$_grub_theme_dir"

  if [[ -f "$GRUB_THEME_ARCHIVE" ]]; then
    tar -xf "$GRUB_THEME_ARCHIVE" -C "$_grub_theme_dir"

    _install_path="$(find "$_grub_theme_dir" -type f -name "install.sh" -exec dirname {} \; | head -n1)"

    if [[ -n "$_install_path" ]]; then
      log_action "Running GRUB theme installer..."
      pushd "$_install_path" >/dev/null
      sudo bash ./install.sh >/dev/null 2>&1 || true
      popd >/dev/null
      log_ok "GRUB theme installed successfully."
    else
      log_warn "install.sh not found in extracted Vimix theme. Skipping."
    fi
  else
    log_warn "GRUB theme archive not found at $GRUB_THEME_ARCHIVE. Skipping."
  fi

  unset _grub_theme_dir _install_path
else
  log_warn "GRUB not detected. Skipping GRUB theme installation."
fi
