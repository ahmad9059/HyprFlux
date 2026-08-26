#!/usr/bin/env bash
# App enablement and editor selection helpers.

enable_asusctl() {
  local log="$1"
  if command -v asusctl >/dev/null 2>&1; then
    # HyprFlux: startup entries live in UserConfigs/startup-apps.lua
    sed -i 's/^    -- hl.exec_cmd("rog-control-center")/    hl.exec_cmd("rog-control-center")/' config/hypr/UserConfigs/startup-apps.lua 2>&1 | tee -a "$log" || true
  fi
}

enable_blueman() {
  local log="$1"
  if command -v blueman-applet >/dev/null 2>&1; then
    # HyprFlux: startup entries live in UserConfigs/startup-apps.lua
    sed -i 's/^    -- hl.exec_cmd("blueman-applet")/    hl.exec_cmd("blueman-applet")/' config/hypr/UserConfigs/startup-apps.lua 2>&1 | tee -a "$log" || true
  fi
}

ensure_keybinds_init() {
  local log="$1"
  # HyprFlux: keybinds are static in configs/keybinds.lua — nothing to init
  echo "${INFO:-[INFO]} [HyprFlux] Keybinds handled by configs/keybinds.lua" 2>&1 | tee -a "$log"
}

install_terminal_configs() {
  local log="$1"

  # Ghostty
  local GHOSTTY_SRC="config/ghostty/ghostty.config"
  local GHOSTTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
  local GHOSTTY_DEST="$GHOSTTY_DIR/config"
  if [ -f "$GHOSTTY_SRC" ]; then
    mkdir -p "$GHOSTTY_DIR"
    install -m 0644 "$GHOSTTY_SRC" "$GHOSTTY_DEST" 2>&1 | tee -a "$log"
  else
    echo "${ERROR:-[ERROR]} - $GHOSTTY_SRC not found; skipping Ghostty config install." 2>&1 | tee -a "$log"
  fi

  # WezTerm
  local WEZTERM_SRC="config/wezterm/wezterm.lua"
  local WEZTERM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm"
  local WEZTERM_DEST="$WEZTERM_DIR/wezterm.lua"
  if [ -f "$WEZTERM_SRC" ]; then
    mkdir -p "$WEZTERM_DIR"
    install -m 0644 "$WEZTERM_SRC" "$WEZTERM_DEST" 2>&1 | tee -a "$log"
  else
    echo "${ERROR:-[ERROR]} - $WEZTERM_SRC not found; skipping WezTerm config install." 2>&1 | tee -a "$log"
  fi
}

choose_default_editor() {
  local log="$1"
  # HyprFlux: Auto-select neovim as default editor if available
  if command -v nvim &>/dev/null; then
    sed -i 's/edit = os.getenv("EDITOR") or .*/edit = os.getenv("EDITOR") or "nvim",/' config/hypr/UserConfigs/user-defaults.lua
    echo "${OK:-[OK]} [HyprFlux] Default editor set to ${MAGENTA:-}nvim${RESET:-}." 2>&1 | tee -a "$log"
  elif command -v vim &>/dev/null; then
    sed -i 's/edit = os.getenv("EDITOR") or .*/edit = os.getenv("EDITOR") or "vim",/' config/hypr/UserConfigs/user-defaults.lua
    echo "${OK:-[OK]} [HyprFlux] Default editor set to ${MAGENTA:-}vim${RESET:-}." 2>&1 | tee -a "$log"
  fi
}
