#!/bin/bash
# ============================================================
# modules/08-gtk.sh — GTK theme settings via gsettings/nwg-look
# ============================================================
should_skip "gtk" && return 0

log_action "Updating GTK theme settings..."

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# Guard: check if gsettings and the GNOME schema are available
if command -v gsettings &>/dev/null; then
  # Verify the schema exists before setting keys
  if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.desktop.interface"; then
    gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME:-HyprFlux-Compact}"
    gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME:-Papirus-Dark}"
    gsettings set org.gnome.desktop.interface cursor-theme "${CURSOR_THEME:-Future-black Cursors}"
    gsettings set org.gnome.desktop.interface font-name "${FONT_NAME:-Adwaita Sans 11}"
    log_ok "GTK Theme, Icon, and Cursor applied."
  else
    log_warn "GNOME desktop interface schema not found. Skipping gsettings."
  fi

  if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.desktop.wm.preferences"; then
    gsettings set org.gnome.desktop.wm.preferences theme "${GTK_THEME:-HyprFlux-Compact}"
  fi
else
  log_warn "gsettings not found. Skipping GTK theme settings."
fi

# Export via nwg-look if available
if command -v nwg-look &>/dev/null; then
  log_action "Exporting GTK settings to settings.ini..."
  nwg-look -x 2>/dev/null || true
else
  log_warn "nwg-look not found. Skipping export step."
fi
