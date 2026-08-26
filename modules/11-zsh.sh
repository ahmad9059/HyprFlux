#!/bin/bash
# ============================================================
# modules/12-zsh.sh — oh-my-zsh theme patch
# ============================================================
# BUG FIX: Guards with file existence check. No longer exit 1
# if the file is missing — just warn and continue.
# ============================================================
should_skip "zsh" && return 0

_zsh_theme_file="$HOME/.oh-my-zsh/themes/refined.zsh-theme"

log_action "Removing leading newline from print -P line in refined theme..."

if [[ -f "$_zsh_theme_file" ]]; then
  if sed -i 's/print -P "\\n\(.*\)"/print -P "\1"/' "$_zsh_theme_file"; then
    log_ok "Successfully removed leading newline from refined.zsh-theme."
  else
    log_warn "Failed to update refined.zsh-theme. Continuing anyway."
  fi
else
  log_warn "oh-my-zsh refined theme not found at $_zsh_theme_file. Skipping."
fi

unset _zsh_theme_file
