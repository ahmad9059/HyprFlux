#!/bin/bash
# ============================================================
# modules/02-dotfiles.sh — Copy new dotfiles to ~/.config
# ============================================================
should_skip "dotfiles" && return 0

log_action "Copying new dotfiles..."

# Remove old config folders that we're about to replace
if [[ -d "$REPO_DIR/.config" ]]; then
  log_action "Removing old config folders from ~/.config that are in ${REPO_DIR}..."
  for folder in "$REPO_DIR/.config/"*; do
    _folder_name="$(basename "$folder")"
    if [[ -d "$HOME/.config/$_folder_name" ]]; then
      rm -rf "$HOME/.config/$_folder_name"
    fi
  done
  log_ok "Old config folders removed successfully."
else
  log_warn "No .config folder found in ${REPO_DIR}, skipping removal."
fi

# Copy new dotfiles
if [[ -d "$REPO_DIR/.config" ]]; then
  mkdir -p "$HOME/.config"

  cp -r "$REPO_DIR/.config/"* "$HOME/.config/"
  cp "$REPO_DIR/.zshrc" "$HOME/"
  cp "$REPO_DIR/.tmux.conf" "$HOME/"

  log_ok "HyprFlux dotfiles copied successfully."
else
  log_error "'$REPO_DIR/.config' does not exist. Dotfiles not copied."
  return 1
fi
