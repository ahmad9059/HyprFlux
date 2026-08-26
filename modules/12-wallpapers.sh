#!/bin/bash
# ============================================================
# modules/13-wallpapers.sh — Wallpaper repo clone
# ============================================================
# BUG FIX: Uses clone_with_retry() instead of infinite while loop.
# ============================================================
should_skip "wallpapers" && return 0

log_action "Updating wallpapers and setup..."

_wallpaper_repo="${WALLPAPER_REPO:-https://github.com/ahmad9059/wallpapers-bank}"
_wallpaper_dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

# Remove old wallpapers folder if exists
if [[ -d "$_wallpaper_dir" ]]; then
  rm -rf "$_wallpaper_dir"
fi

# BUG FIX: max 5 retries instead of infinite loop
if clone_with_retry "$_wallpaper_repo" "$_wallpaper_dir" 5 "--depth=1"; then
  log_ok "Wallpapers cloned successfully to $_wallpaper_dir"
else
  log_warn "Failed to clone wallpapers after 5 attempts. You can clone them manually later."
fi

unset _wallpaper_repo _wallpaper_dir
