#!/bin/bash
# ============================================================
# modules/07-sddm.sh — SDDM theme installation and config
# ============================================================
should_skip "sddm" && return 0

log_action "Setting SDDM theme to '$SDDM_THEME_NAME'..."

# Install theme if source exists
if [[ -d "$SDDM_THEME_SOURCE" ]]; then
  sudo cp -r "$SDDM_THEME_SOURCE" "$SDDM_THEME_DEST"
  log_ok "SDDM theme '$SDDM_THEME_NAME' installed."
else
  log_warn "Theme folder '$SDDM_THEME_SOURCE' not found. Skipping theme installation."
fi

# Ensure config file exists
if [[ ! -f "$SDDM_CONF" ]]; then
  log_warn "'$SDDM_CONF' not found. Creating it..."
  echo "[Theme]" | sudo tee "$SDDM_CONF" >/dev/null
fi

# Update or add Current= line
if grep -q "^\[Theme\]" "$SDDM_CONF"; then
  sudo sed -i "/^\[Theme\]/,/^\[/ s/^Current=.*/Current=$SDDM_THEME_NAME/" "$SDDM_CONF"
  if ! grep -q "^Current=" "$SDDM_CONF"; then
    sudo sed -i "/^\[Theme\]/a Current=$SDDM_THEME_NAME" "$SDDM_CONF"
  fi
else
  printf "\n[Theme]\nCurrent=%s\n" "$SDDM_THEME_NAME" | sudo tee -a "$SDDM_CONF" >/dev/null
fi

log_ok "SDDM theme successfully set to '$SDDM_THEME_NAME'."
