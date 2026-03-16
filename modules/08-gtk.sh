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
_themes_dir="$HOME/.themes"
_theme_path="$_themes_dir/$_gtk_theme"

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# ── 0. Verify the theme was actually installed ──
if [[ ! -d "$_theme_path" ]]; then
  log_error "Theme '$_gtk_theme' not found in $_themes_dir — was 05-themes.sh skipped?"
  log_warn  "Falling back to 'adwaita' for GTK theme."
  _gtk_theme="adwaita"
  _theme_path=""
fi

# ── 1. Install GTK engine dependency (needed for GTK2 engine "adwaita"/"pixmap") ──
if command -v pacman &>/dev/null; then
  sudo pacman -S --needed --noconfirm gtk-engines gtk-engine-murrine 2>/dev/null || true
fi

# ── 2. Write settings.ini for gtk-3.0 and gtk-4.0 ──
#    This is the most reliable method on Hyprland (no GNOME daemon needed).
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

# ── 3. Symlink GTK4 CSS so GTK4 apps actually pick up the theme ──
#    GTK4 ignores settings.ini for visual theming — it reads gtk.css directly.
if [[ -n "$_theme_path" && -f "$_theme_path/gtk-4.0/gtk.css" ]]; then
  ln -sf "$_theme_path/gtk-4.0/gtk.css"      "$HOME/.config/gtk-4.0/gtk.css"
  ln -sf "$_theme_path/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css" 2>/dev/null || true
  # Also symlink assets folder if present
  if [[ -d "$_theme_path/gtk-4.0/assets" ]]; then
    ln -sf "$_theme_path/gtk-4.0/assets" "$HOME/.config/gtk-4.0/assets"
  fi
  log_ok "GTK4 CSS symlinked from $_theme_path/gtk-4.0/."
else
  log_warn "No gtk-4.0/gtk.css found in theme — GTK4 apps will use default styling."
fi

# ── 4. gsettings (best-effort — schema may not be present on Hyprland) ──
if command -v gsettings &>/dev/null; then
  if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.desktop.interface"; then
    gsettings set org.gnome.desktop.interface gtk-theme        "$_gtk_theme"
    gsettings set org.gnome.desktop.interface icon-theme       "$_icon_theme"
    gsettings set org.gnome.desktop.interface cursor-theme     "$_cursor_theme"
    gsettings set org.gnome.desktop.interface font-name        "$_font_name"
    gsettings set org.gnome.desktop.interface color-scheme     "prefer-dark"
    log_ok "gsettings: GTK theme, icon, cursor, font applied."
  else
    log_warn "org.gnome.desktop.interface schema not found — gsettings skipped."
  fi

  if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.desktop.wm.preferences"; then
    gsettings set org.gnome.desktop.wm.preferences theme "$_gtk_theme"
  fi
else
  log_warn "gsettings not found — skipping (settings.ini + CSS symlink already done)."
fi

# ── 5. Export via nwg-look if available ──
if command -v nwg-look &>/dev/null; then
  log_action "Exporting GTK settings via nwg-look..."
  nwg-look -x 2>/dev/null || true
else
  log_warn "nwg-look not found. Skipping export step."
fi

unset _gtk_theme _icon_theme _cursor_theme _font_name _gtk3_conf _gtk4_conf _conf
unset _themes_dir _theme_path
