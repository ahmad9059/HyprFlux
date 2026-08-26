#!/bin/bash
# ============================================================
# modules/04-neovim.sh — Install Neovim config from GitHub
# ============================================================
should_skip "neovim" && return 0

_nvim_config_dir="${NVIM_CONFIG_DIR:-$HOME/.config/nvim}"

log_action "Installing Neovim config from ${REPO_URL_NVIM}..."

if [[ -d "$_nvim_config_dir" ]]; then
  rm -rf "$_nvim_config_dir"
fi

if git clone "$REPO_URL_NVIM" "$_nvim_config_dir"; then
  log_ok "Neovim config installed in ${_nvim_config_dir}."
else
  log_error "Failed to clone Neovim config from ${REPO_URL_NVIM}."
  return 1
fi

# Install Lazy plugins and Mason packages
if command -v nvim &>/dev/null; then
  log_action "Installing and setting up Neovim Lazy, Mason packages..."
  nvim --headless -c 'qa' 2>/dev/null || true
  nvim --headless -c 'Lazy sync' -c 'qa' 2>/dev/null || true
  log_ok "Neovim plugins and Mason packages installed successfully!"
else
  log_warn "nvim binary not found. Skipping plugin installation."
fi

unset _nvim_config_dir
