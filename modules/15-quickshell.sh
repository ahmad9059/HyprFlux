#!/bin/bash
# ============================================================
# modules/15-quickshell.sh — QuickShell config adjustments
# ============================================================
should_skip "quickshell" && return 0

log_action "Setting up QuickShell if installed..."

if command -v qs &>/dev/null; then
  log_info "QuickShell detected, adjusting configs..."

  # Uncomment exec-once line in Startup_Apps.conf
  sed -i '/^\s*#exec-once = qs/s/^#//' "$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"

  # Uncomment qs refresh lines in scripts
  sed -i '/#pkill qs && qs &/s/^#//' "$HOME/.config/hypr/scripts/RefreshNoWaybar.sh"
  sed -i '/#pkill qs && qs &/s/^#//' "$HOME/.config/hypr/scripts/Refresh.sh"

  # Uncomment the quickshell keybind line
  sed -i "/^#bind = \$mainMod, A, global, quickshell:overviewToggle/s/^#//" "$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"

  # Comment out the ags overview keybind if it exists
  sed -i "/^\s*bind\s*=\s*\\\$mainMod,\s*A,\s*exec,\s*pkill rofi\s*||\s*true\s*&&\s*ags\s*-t\s*'overview'/{s/^\s*/#/}" "$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"

  log_ok "QuickShell setup completed."
else
  log_info "QuickShell not installed. Skipping."
fi
