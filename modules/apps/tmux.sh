#!/bin/bash

# ===========================
# Tmux and Tmuxifier Setup Module
# ===========================

setup_tmux() {
  print_section "Setting up Tmux and Tmuxifier"
  
  echo -e "${ACTION} Installing Tmux Plugin Manager (TPM) and tmuxifier...${RESET}"
  
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  
  # Install tmuxifier
  if [[ -d "$HOME/.tmuxifier" ]]; then
    echo -e "${WARN} Existing ~/.tmuxifier found, removing it for a fresh install...${RESET}"
    rm -rf "$HOME/.tmuxifier"
  fi
  
  if git clone "$TMUXIFIER_REPO" "$HOME/.tmuxifier" >>"$LOG_FILE" 2>&1; then
    echo -e "${OK} Official tmuxifier cloned to $HOME/.tmuxifier${RESET}"
  else
    echo -e "${ERROR} Failed to clone tmuxifier repository.${RESET}"
    log_message "ERROR" "Tmuxifier clone failed"
    return 1
  fi
  
  # Copy layouts
  ensure_dir "$HOME/.tmuxifier/layouts"
  if [[ -d "$REPO_DIR/.tmuxifier/layouts" ]]; then
    cp -r "$REPO_DIR/.tmuxifier/layouts/." "$HOME/.tmuxifier/layouts/"
    echo -e "${OK} Tmuxifier layouts copied.${RESET}"
  fi
  
  # Install TPM
  if [[ -d "$tpm_dir" ]]; then
    echo -e "${WARN} TPM already installed at $tpm_dir. Skipping clone.${RESET}"
  else
    if git clone https://github.com/tmux-plugins/tpm "$tpm_dir" >>"$LOG_FILE" 2>&1; then
      echo -e "${OK} TPM cloned successfully.${RESET}"
    else
      echo -e "${ERROR} Failed to clone TPM repository.${RESET}"
      log_message "ERROR" "TPM clone failed"
      return 1
    fi
  fi
  
  # Install TPM plugins
  if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
    "$tpm_dir/bin/install_plugins" >>"$LOG_FILE" 2>&1
    echo -e "${OK} Tmux plugins installed via TPM${RESET}"
  else
    echo -e "${ERROR} TPM install script not found at $tpm_dir/bin/install_plugins${RESET}"
    log_message "ERROR" "TPM plugin installation failed"
    return 1
  fi
  
  log_message "INFO" "Tmux and Tmuxifier setup completed"
  return 0
}