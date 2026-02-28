#!/bin/bash
# ============================================================
# modules/05-themes.sh — GTK themes, icons, and cursors
# ============================================================
should_skip "themes" && return 0

# ====== GTK Themes ======
log_action "Installing themes from ${REPO_DIR}.themes..."

if [[ -d "$REPO_DIR/.themes" ]]; then
  mkdir -p "$HOME/.themes"
  cp -r "$REPO_DIR/.themes/"* "$HOME/.themes/"
  log_ok "Themes installed successfully in ~/.themes."
else
  log_warn "No .themes directory found in ${REPO_DIR}, skipping theme installation."
fi

# ====== Icons (Papirus) ======
if command -v yay &>/dev/null; then
  log_action "Installing 'papirus-icon-theme' via pacman..."
  if sudo pacman -S --needed --noconfirm papirus-icon-theme papirus-folders; then
    log_ok "'papirus-icon-theme' installed successfully."

    # Set folder color to cyan for Papirus-Dark
    log_action "Setting Papirus folders to cyan (Papirus-Dark)."
    if command -v papirus-folders &>/dev/null; then
      papirus-folders -C cyan --theme Papirus-Dark
      log_ok "Papirus folders set to cyan (Papirus-Dark)."
    fi
  else
    log_error "Failed to install 'papirus-icon-theme'."
  fi
else
  log_warn "yay not found. Skipping 'papirus-icon-theme' installation."
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
