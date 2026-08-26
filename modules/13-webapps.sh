#!/bin/bash
# ============================================================
# modules/14-webapps.sh — Chromium PWA desktop entries + icons
# ============================================================
# Reads app list from config/webapps.conf for easy customization.
# ============================================================
should_skip "webapps" && return 0

_wa_desktop_dir="${DESKTOP_DIR:-$HOME/.local/share/applications}"
_wa_icon_dir="${ICON_DIR:-$HOME/.local/share/icons/apps}"
_wa_browser="${BROWSER:-chromium}"
_wa_conf="${WEBAPPS_CONF:-$REPO_DIR/config/webapps.conf}"

log_action "Creating Web Apps and desktop entries..."

mkdir -p "$_wa_desktop_dir" "$_wa_icon_dir"

# ====== Icon download function ======
_download_icon() {
  local url="$1"
  local name="$2"
  local icon_path="$_wa_icon_dir/$name.png"

  if [[ -f "$icon_path" ]]; then
    log_info "Icon for $name already exists. Skipping."
    return
  fi

  log_info "Downloading icon for $name..."

  # Try Homarr (light -> dark -> plain)
  local variant
  for variant in "-light" "-dark" ""; do
    if curl -fsSL "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/${name}${variant}.png" -o "$icon_path" 2>/dev/null; then
      if file --mime-type "$icon_path" | grep -q "image/png"; then
        log_ok "Icon for $name downloaded from Homarr (${variant:-plain})."
        return
      else
        rm -f "$icon_path"
      fi
    fi
  done

  # Fallback: Google S2 favicon API
  if curl -fsSL "https://www.google.com/s2/favicons?sz=128&domain=$url" -o "$icon_path" 2>/dev/null; then
    if file --mime-type "$icon_path" | grep -q "image/png"; then
      log_ok "Icon for $name downloaded via Google S2."
      return
    else
      rm -f "$icon_path"
    fi
  fi

  # Fallback: direct favicon.ico from site
  if curl -fsSL "$url/favicon.ico" -o "$icon_path" 2>/dev/null; then
    if file --mime-type "$icon_path" | grep -q "image/"; then
      log_ok "Icon for $name downloaded directly from $url/favicon.ico."
      return
    else
      rm -f "$icon_path"
    fi
  fi

  log_warn "No icon available for $name after all fallbacks."
}

# ====== Desktop entry creation ======
_make_desktop_entry() {
  local name="$1"
  local url="$2"
  local icon="$3"
  local desktop_file="$_wa_desktop_dir/$icon.desktop"

  {
    echo "[Desktop Entry]"
    echo "Name=$name"
    echo "Exec=$_wa_browser --new-window --ozone-platform=wayland --app=$url"
    [[ -f "$_wa_icon_dir/$icon.png" ]] && echo "Icon=$_wa_icon_dir/$icon.png"
    echo "Type=Application"
    echo "Categories=Network;WebApp;"
  } >"$desktop_file"

  if [[ -f "$desktop_file" ]]; then
    log_ok "Created desktop entry for $name."
  else
    log_error "Failed to create desktop entry for $name."
  fi
}

# ====== Process web apps from config file ======
if [[ -f "$_wa_conf" ]]; then
  while IFS= read -r _wa_line; do
    # Skip comments and blank lines
    [[ "$_wa_line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${_wa_line// /}" ]] && continue

    IFS="|" read -r _wa_name _wa_url _wa_icon <<<"$_wa_line"
    _download_icon "$_wa_url" "$_wa_icon"
    _make_desktop_entry "$_wa_name" "$_wa_url" "$_wa_icon"
  done <"$_wa_conf"
else
  log_warn "Web apps config not found at $_wa_conf. Skipping."
fi

log_ok "All web apps created in $_wa_desktop_dir with icons in $_wa_icon_dir."

unset _wa_desktop_dir _wa_icon_dir _wa_browser _wa_conf _wa_line _wa_name _wa_url _wa_icon
