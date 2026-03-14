#!/bin/bash
# ============================================================
# modules/08-gtk.sh — GTK theme settings via gsettings/nwg-look
# ============================================================
should_skip "gtk" && return 0

log_action "Updating GTK theme settings..."

_gtk_theme="${GTK_THEME:-HyprFlux-Compact}"
_icon_theme="${ICON_THEME:-Papirus-Dark}"
_cursor_theme="${CURSOR_THEME:-Future-black Cursors}"
_font_name="${FONT_NAME:-Adwaita Sans 11}"

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# ── 1. Write settings.ini directly (works on Hyprland without GNOME schema) ──
_gtk3_conf="$HOME/.config/gtk-3.0/settings.ini"
_gtk4_conf="$HOME/.config/gtk-4.0/settings.ini"

for _conf in "$_gtk3_conf" "$_gtk4_conf"; do
  cat > "$_conf" <<EOF
[Settings]
gtk-theme-name=${_gtk_theme}
gtk-icon-theme-name=${_icon_theme}
gtk-cursor-theme-name=${_cursor_theme}
gtk-font-name=${_font_name}
gtk-application-prefer-dark-theme=1
EOF
done
log_ok "GTK settings.ini written for gtk-3.0 and gtk-4.0."

# ── 2. gsettings (best-effort — may not be available on Hyprland) ──
if command -v gsettings &>/dev/null; then
  if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.desktop.interface"; then
    gsettings set org.gnome.desktop.interface gtk-theme        "$_gtk_theme"
    gsettings set org.gnome.desktop.interface icon-theme       "$_icon_theme"
    gsettings set org.gnome.desktop.interface cursor-theme     "$_cursor_theme"
    gsettings set org.gnome.desktop.interface font-name        "$_font_name"
    log_ok "gsettings: GTK theme, icon, cursor, font applied."
  else
    log_warn "org.gnome.desktop.interface schema not found — gsettings skipped."
  fi

  if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.desktop.wm.preferences"; then
    gsettings set org.gnome.desktop.wm.preferences theme "$_gtk_theme"
  fi
else
  log_warn "gsettings not found — skipping (settings.ini already written above)."
fi

# ── 3. Export via nwg-look if available ──
if command -v nwg-look &>/dev/null; then
  log_action "Exporting GTK settings via nwg-look..."
  nwg-look -x 2>/dev/null || true
else
  log_warn "nwg-look not found. Skipping export step."
fi

unset _gtk_theme _icon_theme _cursor_theme _font_name _gtk3_conf _gtk4_conf _conf
