#!/bin/bash
# ============================================================
# modules/19-ai-tools.sh — AI tools setup
# ============================================================
should_skip "ai-tools" && return 0

log_action "Installing AI tools from AUR..."

read -r -a _ai_aur_packages <<< "${AI_TOOLS_AUR_PACKAGES:-}"

if [[ ${#_ai_aur_packages[@]} -eq 0 ]]; then
  log_info "No AI tools configured."
  return 0
fi

if ! install_yay 5 "${_ai_aur_packages[@]}"; then
  log_warn "Some AI tools failed to install."
fi

unset _ai_aur_packages
