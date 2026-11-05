#!/bin/bash
# ============================================================
# modules/04-themes.sh — GTK themes, icons, and cursors
# ============================================================
should_skip "themes" && return 0

# ====== GTK Themes ======
log_action "Installing themes from ${REPO_DIR}/.themes..."

if [[ -d "$REPO_DIR/.themes" ]]; then
  mkdir -p "$HOME/.themes"
  cp -r "$REPO_DIR/.themes/"* "$HOME/.themes/"
  log_ok "Themes installed successfully in ~/.themes."
else
  log_warn "No .themes directory found in ${REPO_DIR}, skipping theme installation."
fi

# ====== Icons (Papirus) ======
# Installed via pacman directly (official repo) — no AUR helper needed.
log_action "Installing 'papirus-icon-theme' via pacman..."
if sudo pacman -S --needed --noconfirm papirus-icon-theme; then
  log_ok "'papirus-icon-theme' installed successfully."

  # Set folder color to cyan for Papirus-Dark
  log_action "Setting Papirus folders to cyan (Papirus-Dark)."
  sudo install -Dm755 "$REPO_DIR/utilities/papirus-cyan.sh" \
    /usr/local/libexec/hyprflux-papirus-cyan || return 1
  sudo install -Dm644 "$REPO_DIR/config/pacman-hooks/hyprflux-papirus-cyan.hook" \
    /etc/pacman.d/hooks/hyprflux-papirus-cyan.hook || return 1
  sudo /usr/local/libexec/hyprflux-papirus-cyan || return 1
  log_ok "Papirus folders set to cyan (Papirus-Dark); upgrade hook installed."
else
  log_error "Failed to install 'papirus-icon-theme'."
  return 1
fi

# ====== Cursor theme (Future Black) ======
_cursor_archive="$REPO_DIR/utilities/Future-black-cursors.tar.gz"
_icons_dir="$HOME/.icons"

mkdir -p "$_icons_dir"

if [[ -f "$_cursor_archive" ]]; then
  if tar -xzf "$_cursor_archive" -C "$_icons_dir"; then
    log_ok "Future Black cursors installed to $_icons_dir."
  else
    log_error "Failed to extract Future Black cursors from $_cursor_archive."
  fi
else
  log_warn "Cursor archive not found at $_cursor_archive. Skipping."
fi

unset _cursor_archive _icons_dir
