#!/bin/bash
# ============================================================
# modules/06-waybar.sh — Waybar config verify and reload
# ============================================================
should_skip "waybar" && return 0

# NOTE: module 02-dotfiles already deploys the real waybar files
# (config + style.css + include files). This module only verifies
# they exist and reloads waybar if it is running.
# Old symlink behaviour was removed: the repo ships real files now.

if [[ ! -f "$WAYBAR_LAYOUT_TARGET" ]]; then
  log_warn "Waybar config not found at ${WAYBAR_LAYOUT_TARGET}, skipping."
  return 0
fi
if [[ ! -f "$WAYBAR_STYLE_TARGET" ]]; then
  log_warn "Waybar style not found at ${WAYBAR_STYLE_TARGET}, skipping."
  return 0
fi

log_ok "Waybar config and style verified."

if pgrep -x "waybar" &>/dev/null; then
  pkill -SIGUSR2 waybar || true
  log_ok "Waybar reloaded."
else
  log_warn "Waybar not running. Style will apply on next launch."
fi