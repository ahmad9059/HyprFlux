#!/bin/bash
# ============================================================
# modules/06-waybar.sh — Waybar symlinks and reload
# ============================================================
should_skip "waybar" && return 0

log_action "Linking custom Waybar style and layout..."

# BUG FIX: Check BOTH style and layout files exist before symlinking
if [[ -f "$CUSTOM_WAYBAR_STYLE" ]] && [[ -f "$CUSTOM_WAYBAR_LAYOUT" ]]; then
  ln -sf "$CUSTOM_WAYBAR_LAYOUT" "$WAYBAR_LAYOUT_TARGET"
  ln -sf "$CUSTOM_WAYBAR_STYLE" "$WAYBAR_STYLE_TARGET"

  if pgrep -x "waybar" &>/dev/null; then
    pkill -SIGUSR2 waybar || true
    log_ok "Waybar style applied and reloaded."
  else
    log_warn "Waybar not running. Style will apply on next launch."
  fi
elif [[ ! -f "$CUSTOM_WAYBAR_STYLE" ]]; then
  log_warn "Custom Waybar style not found at ${CUSTOM_WAYBAR_STYLE}, skipping."
elif [[ ! -f "$CUSTOM_WAYBAR_LAYOUT" ]]; then
  log_warn "Custom Waybar layout not found at ${CUSTOM_WAYBAR_LAYOUT}, skipping."
fi
