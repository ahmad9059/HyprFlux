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

# ============================================================
# awww wallpaper daemon — install prebuilt binary (no source build)
# ============================================================
# awww-git on AUR is a rust source build (needs cargo+dav1d+scdoc, slow and
# fragile). HyprFlux ships a prebuilt awww+awww-daemon (utilities/awww-prebuilt.tar.xz)
# so installs never compile it. Fallback: yay awww-git if the prebuilt is missing.
_awww_archive="${AWWW_PREBUILT_ARCHIVE:-$REPO_DIR/utilities/awww-prebuilt.tar.xz}"
_awww_tmp="$(mktemp -d)"
_awww_ok=no

if [[ -f "$_awww_archive" ]] && tar -xJf "$_awww_archive" -C "$_awww_tmp" 2>/dev/null; then
  if sudo install -Dm755 "$_awww_tmp/usr/bin/awww" /usr/local/bin/awww 2>/dev/null &&
     sudo install -Dm755 "$_awww_tmp/usr/bin/awww-daemon" /usr/local/bin/awww-daemon 2>/dev/null; then
    log_ok "awww prebuilt binary installed (v$(/usr/local/bin/awww --version 2>/dev/null | head -1 || echo unknown))."
    _awww_ok=yes
  else
    log_warn "Failed to install awww prebuilt (sudo/install issue) — falling back to source build."
  fi
else
  log_warn "awww prebuilt archive missing at $_awww_archive — falling back to source build."
fi
rm -rf "$_awww_tmp"

if [[ "$_awww_ok" != yes ]]; then
  if command -v yay &>/dev/null; then
    log_action "Building awww-git from AUR (deps: rust, dav1d, scdoc)..."
    yay -S --noconfirm awww-git 2>&1 | tail -3 || log_warn "awww-git build failed — wallpaper daemon unavailable."
  else
    log_warn "awww unavailable (no prebuilt, no yay). Wallpaper auto-change won't work."
  fi
fi
unset _awww_archive _awww_tmp _awww_ok

unset _wallpaper_repo _wallpaper_dir
