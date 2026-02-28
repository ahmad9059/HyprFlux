#!/bin/bash
# ============================================================
# modules/16-bibata.sh — Bibata Hyprcursor installation
# ============================================================
# BUG FIX: Cursor size unified to 24 (was 20 in sed, 24 in create).
# ============================================================
should_skip "bibata" && return 0

_bib_cursor_url="${BIBATA_CURSOR_URL:-https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor/releases/download/1.0/hypr_Bibata-Modern-Classic.tar.gz}"
_bib_cursor_dir="$HOME/.icons"
_bib_env_file="$HOME/.config/hypr/UserConfigs/ENVariables.conf"
_bib_target_dir="$_bib_cursor_dir/Bibata-Modern-Classic"
_bib_cursor_size="${CURSOR_SIZE:-24}"

log_action "Downloading and installing Bibata Hyprcursor..."

mkdir -p "$_bib_cursor_dir"

# Remove any old cursor folder
if [[ -d "$_bib_target_dir" ]]; then
  rm -rf "$_bib_target_dir"
  rm -rf "$HOME/.icons/Bibata-Modern-Ice"
  log_info "Removed old Bibata-Modern-Classic cursor folder."
fi

# Download
if curl -fsSL "$_bib_cursor_url" -o /tmp/hyprcursor.tar.gz; then
  log_ok "Cursor archive downloaded successfully."

  mkdir -p "$_bib_target_dir"

  if tar -xzf /tmp/hyprcursor.tar.gz -C "$_bib_target_dir"; then
    log_ok "Cursor extracted into $_bib_target_dir."

    # Update Hyprland ENVariables.conf
    if [[ -f "$_bib_env_file" ]]; then
      sed -i "s/^env = HYPRCURSOR_THEME.*/env = HYPRCURSOR_THEME,Bibata-Modern-Classic/" "$_bib_env_file"
      # BUG FIX: cursor size unified to $_bib_cursor_size (was 20 here, 24 in else branch)
      sed -i "s/^env = HYPRCURSOR_SIZE.*/env = HYPRCURSOR_SIZE,$_bib_cursor_size/" "$_bib_env_file"
      log_ok "Updated Hyprland ENVariables.conf with new cursor theme."
    else
      log_warn "ENVariables.conf not found, creating a new one."
      mkdir -p "$(dirname "$_bib_env_file")"
      {
        echo "env = HYPRCURSOR_THEME,Bibata-Modern-Classic"
        echo "env = HYPRCURSOR_SIZE,$_bib_cursor_size"
      } >"$_bib_env_file"
      log_ok "Created ENVariables.conf with cursor settings."
    fi
  else
    log_error "Failed to extract cursor archive."
  fi
else
  log_error "Failed to download cursor from $_bib_cursor_url."
fi

# Cleanup
rm -f /tmp/hyprcursor.tar.gz

unset _bib_cursor_url _bib_cursor_dir _bib_env_file _bib_target_dir _bib_cursor_size
