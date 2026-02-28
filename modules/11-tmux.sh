#!/bin/bash
# ============================================================
# modules/11-tmux.sh — TPM + Tmuxifier + layouts
# ============================================================
should_skip "tmux" && return 0

log_action "Installing Tmux Plugin Manager (TPM) and tmuxifier..."

_tpm_dir="$HOME/.tmux/plugins/tpm"
_tmuxifier_repo="${TMUXIFIER_REPO:-https://github.com/jimeh/tmuxifier.git}"

# ====== Tmuxifier installation ======
if [[ -d "$HOME/.tmuxifier" ]]; then
  log_warn "Existing ~/.tmuxifier found, removing it for a fresh install..."
  rm -rf "$HOME/.tmuxifier"
fi

if git clone "$_tmuxifier_repo" "$HOME/.tmuxifier"; then
  log_ok "Official tmuxifier cloned to $HOME/.tmuxifier"
else
  log_error "Failed to clone tmuxifier. Continuing without it."
fi

# Copy layouts
mkdir -p "$HOME/.tmuxifier/layouts"
if [[ -d "$REPO_DIR/.tmuxifier/layouts" ]]; then
  cp -r "$REPO_DIR/.tmuxifier/layouts/." "$HOME/.tmuxifier/layouts/"
  log_ok "Tmuxifier layouts copied."
fi

# ====== TPM installation ======
if [[ -d "$_tpm_dir" ]]; then
  log_warn "TPM already installed at $_tpm_dir. Skipping clone."
else
  if git clone https://github.com/tmux-plugins/tpm "$_tpm_dir"; then
    log_ok "TPM cloned to $_tpm_dir."
  else
    log_error "Failed to clone TPM."
  fi
fi

# Install TPM plugins without opening tmux
if [[ -x "$_tpm_dir/bin/install_plugins" ]]; then
  "$_tpm_dir/bin/install_plugins"
  log_ok "Tmux plugins installed via TPM."
else
  log_warn "TPM install script not found at $_tpm_dir/bin/install_plugins."
fi

unset _tpm_dir _tmuxifier_repo
