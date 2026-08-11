#!/bin/bash
# ============================================================
# modules/16-bibata.sh — Bibata Hyprcursor installation
# ============================================================
should_skip "bibata" && return 0

_bib_archive="${BIBATA_CURSOR_ARCHIVE:-$REPO_DIR/utilities/Bibata-Modern-Classic.tar.xz}"
_bib_cursor_dir="$HOME/.icons"
_bib_env_file="$HOME/.config/hypr/UserConfigs/ENVariables.conf"
_bib_target_dir="$_bib_cursor_dir/Bibata-Modern-Classic"
_bib_cursor_size="${CURSOR_SIZE:-24}"

log_action "Installing bundled Bibata Hyprcursor..."

mkdir -p "$_bib_cursor_dir"

if [[ ! -f "$_bib_archive" ]]; then
  log_error "Bibata archive not found at $_bib_archive."
  return 1
fi

# Clean any previous install before extracting.
rm -rf "$_bib_target_dir" "$HOME/.icons/Bibata-Modern-Ice"

_bib_tmp="$(mktemp -d)"

if ! tar -xJf "$_bib_archive" -C "$_bib_tmp"; then
  log_error "Failed to extract Bibata archive: $_bib_archive"
  rm -rf "$_bib_tmp"
  return 1
fi

# Expected archive layout is:
#   Bibata-Modern-Classic/
#     manifest.hl
#     hyprcursors/
# But normalize defensively in case upstream/archive layout changes.
_bib_extracted_dir="$_bib_tmp/Bibata-Modern-Classic"

if [[ ! -d "$_bib_extracted_dir" ]]; then
  _bib_extracted_dir="$(find "$_bib_tmp" -mindepth 1 -maxdepth 2 -type d -name 'Bibata-Modern-Classic' | head -n 1)"
fi

if [[ -z "$_bib_extracted_dir" || ! -d "$_bib_extracted_dir" ]]; then
  log_error "Could not find Bibata-Modern-Classic directory inside archive."
  rm -rf "$_bib_tmp"
  return 1
fi

mkdir -p "$_bib_target_dir"
cp -a "$_bib_extracted_dir/." "$_bib_target_dir/"

# Normalize edge cases:
# If files were extracted flat into target dir, move them under hyprcursors/.
if [[ -f "$_bib_target_dir/left_ptr.hlc" || -f "$_bib_target_dir/wayland-cursor.hlc" ]]; then
  mkdir -p "$_bib_target_dir/hyprcursors"
  find "$_bib_target_dir" -maxdepth 1 -type f -name '*.hlc' -exec mv -t "$_bib_target_dir/hyprcursors" {} +
fi

# Validate final structure.
if [[ ! -f "$_bib_target_dir/manifest.hl" || ! -d "$_bib_target_dir/hyprcursors" ]]; then
  log_error "Bibata cursor install is incomplete. Expected manifest.hl and hyprcursors/ inside $_bib_target_dir"
  rm -rf "$_bib_tmp"
  return 1
fi

rm -rf "$_bib_tmp"
log_ok "Bibata cursor extracted into $_bib_target_dir."

# Update Hyprland ENVariables.conf
if [[ -f "$_bib_env_file" ]]; then
  sed -i "s/^env = HYPRCURSOR_THEME.*/env = HYPRCURSOR_THEME,Bibata-Modern-Classic/" "$_bib_env_file"
  sed -i "s/^env = HYPRCURSOR_SIZE.*/env = HYPRCURSOR_SIZE,$_bib_cursor_size/" "$_bib_env_file"
  log_ok "Updated Hyprland ENVariables.conf with Bibata cursor settings."
else
  log_warn "ENVariables.conf not found, creating a new one."
  mkdir -p "$(dirname "$_bib_env_file")"
  {
    echo "env = HYPRCURSOR_THEME,Bibata-Modern-Classic"
    echo "env = HYPRCURSOR_SIZE,$_bib_cursor_size"
  } > "$_bib_env_file"
  log_ok "Created ENVariables.conf with cursor settings."
fi

unset _bib_archive _bib_cursor_dir _bib_env_file _bib_target_dir _bib_cursor_size
unset _bib_tmp _bib_extracted_dir
