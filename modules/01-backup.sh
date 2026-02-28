#!/bin/bash
# ============================================================
# modules/01-backup.sh — Backup existing dotfiles
# ============================================================
should_skip "backup" && return 0

log_action "Backing up existing dotfiles to ${BACKUP_DIR}..."

# Remove existing backup if present
if [[ -d "$BACKUP_DIR" ]]; then
  log_action "Existing backup found. Removing old backup..."
  rm -rf "$BACKUP_DIR"
fi

if mkdir -p "$BACKUP_DIR"; then
  # Copy only if files/folders exist
  if [[ -d "$HOME/.config" ]]; then
    cp -r "$HOME/.config" "$BACKUP_DIR/"
  fi
  if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$BACKUP_DIR/"
  fi
  if [[ -f "$HOME/.tmux.conf" ]]; then
    cp "$HOME/.tmux.conf" "$BACKUP_DIR/"
  fi
  log_ok "Backup completed and stored in ${BACKUP_DIR}."
else
  log_error "Failed to create backup directory at ${BACKUP_DIR}."
  return 1
fi
