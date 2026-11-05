#!/bin/bash
# ============================================================
# modules/06-sddm.sh — SDDM theme installation and config
# ============================================================
should_skip "sddm" && return 0

# The theme imports Qt5Compat.GraphicalEffects and Qt Quick multimedia/SVG.
# Own these dependencies here so normal and ISO installations stay identical.
sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-virtualkeyboard \
  qt6-multimedia qt6-5compat || { log_error 'SDDM theme dependencies failed.'; return 1; }

log_action "Setting SDDM theme to '$SDDM_THEME_NAME'..."

# Install theme if source exists
if [[ -d "$SDDM_THEME_SOURCE" ]]; then
  sudo mkdir -p "$SDDM_THEME_DEST" || return 1
  sudo cp -a "$SDDM_THEME_SOURCE/." "$SDDM_THEME_DEST/" || return 1
  log_ok "SDDM theme '$SDDM_THEME_NAME' installed."
else
  log_error "Theme folder '$SDDM_THEME_SOURCE' not found."
  return 1
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
