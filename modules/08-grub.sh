#!/bin/bash
# ============================================================
# modules/08-grub.sh — HyprFlux GRUB theme installation
# ============================================================
# Edge-case hardened:
#   - skips cleanly when GRUB is absent
#   - validates the theme archive before extraction
#   - removes any existing HyprFlux theme first (idempotent re-runs)
#   - verifies the theme actually installed (theme.txt present +
#     GRUB_THEME wired in /etc/default/grub), with a manual fallback
#   - never aborts the install (cosmetic step — always returns 0)
# ============================================================
should_skip "grub" && return 0

log_action "Checking for GRUB..."

# 1. GRUB present? (either the binary or an existing boot dir)
if ! command -v grub-install &>/dev/null && ! command -v grub-mkconfig &>/dev/null; then
  log_warn "GRUB not detected. Skipping GRUB theme installation."
  return 0
fi

_grub_theme_dir="${GRUB_THEME_DIR:-/tmp/hyprflux-grub}"
_grub_archive="${GRUB_THEME_ARCHIVE:-$REPO_DIR/utilities/HyprFlux-1080p.tar.xz}"
_grub_theme_name="HyprFlux"
_grub_theme_dest="/usr/share/grub/themes/$_grub_theme_name"
_grub_conf="/etc/default/grub"

# 2. Archive present + valid?
if [[ ! -f "$_grub_archive" ]]; then
  log_warn "GRUB theme archive not found at $_grub_archive. Skipping."
  return 0
fi
if ! tar -tJf "$_grub_archive" >/dev/null 2>&1; then
  log_warn "GRUB theme archive is corrupt/unreadable ($_grub_archive). Skipping."
  return 0
fi

# 3. Clean extraction dir, then extract fresh
rm -rf "$_grub_theme_dir"
mkdir -p "$_grub_theme_dir" || { log_warn "Cannot create $_grub_theme_dir. Skipping."; return 0; }

if ! tar -xJf "$_grub_archive" -C "$_grub_theme_dir" 2>/dev/null; then
  log_warn "Failed to extract GRUB theme archive. Skipping."
  return 0
fi

# 4. Locate the bundled install.sh (theme dir containing it)
_install_path="$(find "$_grub_theme_dir" -type f -name "install.sh" -exec dirname {} \; 2>/dev/null | head -n1)"
if [[ -z "$_install_path" ]]; then
  log_warn "install.sh not found in extracted theme. Skipping."
  return 0
fi

# 5. Remove any previous HyprFlux theme so re-runs are clean
if [[ -d "$_grub_theme_dest" ]]; then
  log_info "Removing previous $_grub_theme_name theme..."
  sudo rm -rf "$_grub_theme_dest"
fi

# 6. Run the bundled installer (as root; capture output for diagnosis)
log_action "Running HyprFlux GRUB theme installer..."
(
  cd "$_install_path" || exit 1
  sudo bash ./install.sh
) > /tmp/hyprflux-grub-install.log 2>&1
_grub_install_rc=$?

if [[ $_grub_install_rc -ne 0 ]]; then
  log_warn "GRUB theme installer exited $_grub_install_rc (see /tmp/hyprflux-grub-install.log). Trying manual install..."
  # Manual fallback: copy theme + wire config ourselves
  if [[ -d "$_install_path/$_grub_theme_name" ]]; then
    sudo mkdir -p "$_grub_theme_dest"
    sudo cp -a "$_install_path/$_grub_theme_name/." "$_grub_theme_dest/" 2>/dev/null \
      && log_ok "Theme copied manually."
  fi
fi

# 7. VERIFY: theme.txt present
if [[ ! -f "$_grub_theme_dest/theme.txt" ]]; then
  log_warn "HyprFlux GRUB theme files not found at $_grub_theme_dest — theme NOT installed."
  rm -rf "$_grub_theme_dir"
  return 0
fi
log_ok "HyprFlux GRUB theme files present."

# 8. VERIFY/WIRE: GRUB_THEME in /etc/default/grub
if [[ ! -f "$_grub_conf" ]]; then
  log_warn "$_grub_conf missing — cannot set GRUB_THEME. Skipping."
  rm -rf "$_grub_theme_dir"
  return 0
fi

if grep -q "^GRUB_THEME=" "$_grub_conf"; then
  sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$_grub_theme_dest/theme.txt\"|" "$_grub_conf"
else
  echo "GRUB_THEME=\"$_grub_theme_dest/theme.txt\"" | sudo tee -a "$_grub_conf" >/dev/null
fi
log_ok "GRUB_THEME wired to HyprFlux theme."

# 9. Regenerate grub.cfg so the theme takes effect now
log_action "Regenerating grub.cfg..."
if command -v grub-mkconfig &>/dev/null; then
  sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 \
    && log_ok "grub.cfg regenerated." \
    || log_warn "grub-mkconfig failed — theme applies on next boot-image rebuild."
else
  log_warn "grub-mkconfig not found — cannot regenerate now (non-fatal)."
fi

# 10. Cleanup temp
rm -rf "$_grub_theme_dir"
log_ok "HyprFlux GRUB theme installation complete."

unset _grub_theme_dir _grub_archive _grub_theme_name _grub_theme_dest _grub_conf _install_path _grub_install_rc
return 0