#!/bin/bash
# ============================================================
# modules/10-plymouth.sh — HyprFlux Plymouth theme + mkinitcpio + GRUB
# ============================================================
# BUG FIX: Plymouth failure no longer kills the entire install.
# This is a cosmetic boot screen — failure should be non-fatal.
# ============================================================
should_skip "plymouth" && return 0

log_action "Installing Plymouth..."

# Install plymouth package if not present
if ! pacman -Qi plymouth &>/dev/null; then
  if ! sudo pacman -S --needed --noconfirm plymouth; then
    log_warn "Failed to install Plymouth. Skipping Plymouth setup."
    return 0
  fi
  log_ok "Plymouth installed successfully."
else
  log_info "Plymouth already installed."
fi

# Extract/copy Plymouth theme
_plymouth_theme_archive="${PLYMOUTH_THEME_ARCHIVE:-$REPO_DIR/utilities/hyprflux-plymouth.tar.xz}"
_plymouth_theme_dir="${PLYMOUTH_THEME_DIR:-/tmp/hyprflux-plymouth}"
_plymouth_theme_name="${PLYMOUTH_THEME_NAME:-hyprflux}"
_plymouth_dest="/usr/share/plymouth/themes"
_mkinitcpio_conf="/etc/mkinitcpio.conf"
_grub_conf="/etc/default/grub"

if [[ -f "$_plymouth_theme_archive" ]]; then
  log_action "Extracting Plymouth theme archive..."
  rm -rf "$_plymouth_theme_dir"
  mkdir -p "$_plymouth_theme_dir"
  if ! tar -C "$_plymouth_theme_dir" --strip-components=1 -xJf "$_plymouth_theme_archive"; then
    log_warn "Failed to extract Plymouth theme archive. Skipping."
    return 0
  fi
elif [[ -d "$_plymouth_theme_dir" ]]; then
  log_info "Using existing extracted Plymouth theme directory $_plymouth_theme_dir."
else
  log_warn "Plymouth theme archive $_plymouth_theme_archive not found. Skipping Plymouth setup."
  return 0
fi

log_action "Copying theme '$_plymouth_theme_name' to $_plymouth_dest..."
sudo mkdir -p "$_plymouth_dest"
sudo rm -rf "$_plymouth_dest/$_plymouth_theme_name"
if ! sudo cp -r "$_plymouth_theme_dir" "$_plymouth_dest/$_plymouth_theme_name"; then
  log_warn "Failed to copy Plymouth theme. Skipping."
  return 0
fi
log_ok "Theme '$_plymouth_theme_name' installed."

# Enable Plymouth in mkinitcpio
if grep -q "plymouth" "$_mkinitcpio_conf"; then
  log_info "Plymouth hook already present in mkinitcpio.conf."
else
  log_action "Adding plymouth hook to mkinitcpio.conf..."
  sudo sed -i 's/HOOKS=(/HOOKS=(plymouth /' "$_mkinitcpio_conf"
  log_ok "Plymouth hook added to mkinitcpio.conf."
fi

# Set Plymouth theme
log_action "Setting Plymouth theme to '$_plymouth_theme_name'..."
if ! sudo plymouth-set-default-theme -R "$_plymouth_theme_name" 2>/dev/null; then
  log_warn "Failed to set Plymouth theme. Continuing anyway."
fi

# Update GRUB / kernel params
if [[ -f "$_grub_conf" ]]; then
  log_action "Ensuring 'quiet splash' are enabled in GRUB..."
  if ! grep -q "splash" "$_grub_conf"; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet splash /' "$_grub_conf"
    sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
    log_ok "GRUB updated with quiet splash."
  elif ! grep -q "quiet" "$_grub_conf"; then
    sudo sed -i 's/splash/quiet splash/' "$_grub_conf"
    sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
    log_ok "GRUB updated to include quiet."
  else
    log_info "'quiet splash' already configured in GRUB."
  fi
else
  log_warn "$_grub_conf not found. Skipping GRUB config update."
fi

# Rebuild initramfs
log_action "Rebuilding initramfs..."
if sudo mkinitcpio -P 2>/dev/null; then
  log_ok "Initramfs rebuilt successfully."
else
  log_warn "Failed to rebuild initramfs. You may need to run 'sudo mkinitcpio -P' manually."
fi

log_ok "Plymouth with theme '$_plymouth_theme_name' is ready! Reboot to see it."

unset _plymouth_theme_archive _plymouth_theme_dir _plymouth_theme_name _plymouth_dest _mkinitcpio_conf _grub_conf
