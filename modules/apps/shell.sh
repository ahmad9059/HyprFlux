#!/bin/bash

# ===========================
# Shell Configuration Module
# ===========================

setup_shell_refinements() {
  print_section "Applying Shell Refinements"
  
  echo -e "${ACTION} Removing leading newline from print -P line in refined theme...${RESET}"

  local refined_theme="$HOME/.oh-my-zsh/themes/refined.zsh-theme"
  
  if [[ ! -f "$refined_theme" ]]; then
    echo -e "${WARN} refined.zsh-theme not found. Skipping refinement.${RESET}"
    return 0
  fi

  if sed -i 's/print -P "\\n\(.*\)"/print -P "\1"/' "$refined_theme"; then
    echo -e "${OK} Successfully removed leading newline from refined.zsh-theme.${RESET}"
    log_message "INFO" "Shell refinements applied"
    return 0
  else
    echo -e "${ERROR} Failed to update refined.zsh-theme.${RESET}"
    log_message "ERROR" "Shell refinements failed"
    return 1
  fi
}