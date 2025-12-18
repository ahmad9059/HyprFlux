#!/bin/bash

# ===========================
# Web Applications Setup Module
# ===========================

# Load webapp configuration
load_webapp_config() {
  local script_dir="$(get_script_dir)"
  source "$script_dir/config/webapps.conf"
}

# Download icon for webapp
download_webapp_icon() {
  local url="$1"
  local name="$2"
  local icon_path="$ICON_DIR/$name.png"

  if [[ -f "$icon_path" ]]; then
    echo -e "${NOTE} Icon for $name already exists. Skipping.${RESET}"
    return 0
  fi

  echo -e "${NOTE} Downloading icon for $name...${RESET}"

  # Try Homarr (light → dark → plain)
  for variant in "-light" "-dark" ""; do
    if curl -fsSL "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/${name}${variant}.png" -o "$icon_path" 2>>"$LOG_FILE"; then
      if file --mime-type "$icon_path" | grep -q "image/png"; then
        echo -e "${OK} Icon for $name downloaded from Homarr (${variant:-plain}).${RESET}"
        return 0
      else
        echo -e "${WARN} Homarr returned invalid file for $name (${variant:-plain}). Retrying...${RESET}"
        rm -f "$icon_path"
      fi
    fi
  done

  # Fallback: Google S2 favicon API
  if curl -fsSL "https://www.google.com/s2/favicons?sz=128&domain=$url" -o "$icon_path" 2>>"$LOG_FILE"; then
    if file --mime-type "$icon_path" | grep -q "image/png"; then
      echo -e "${OK} Icon for $name downloaded via Google S2.${RESET}"
      return 0
    else
      echo -e "${WARN} Google S2 returned invalid file for $name. Retrying...${RESET}"
      rm -f "$icon_path"
    fi
  fi

  # Fallback: direct favicon.ico from site
  if curl -fsSL "$url/favicon.ico" -o "$icon_path" 2>>"$LOG_FILE"; then
    if file --mime-type "$icon_path" | grep -q "image/"; then
      echo -e "${OK} Icon for $name downloaded directly from $url/favicon.ico.${RESET}"
      return 0
    else
      echo -e "${WARN} Invalid favicon from $url/favicon.ico. Skipping.${RESET}"
      rm -f "$icon_path"
    fi
  fi

  echo -e "${WARN} No icon available for $name after all fallbacks.${RESET}"
  return 1
}

# Create desktop entry for webapp
create_webapp_desktop_entry() {
  local name="$1"
  local url="$2"
  local icon="$3"
  local desktop_file="$DESKTOP_DIR/$icon.desktop"

  {
    echo "[Desktop Entry]"
    echo "Name=$name"
    echo "Exec=$BROWSER --new-window --ozone-platform=wayland --app=$url"
    [[ -f "$ICON_DIR/$icon.png" ]] && echo "Icon=$ICON_DIR/$icon.png"
    echo "Type=Application"
    echo "Categories=Network;WebApp;"
  } >"$desktop_file"

  if [[ -f "$desktop_file" ]]; then
    echo -e "${OK} Created desktop entry for $name.${RESET}"
    return 0
  else
    echo -e "${ERROR} Failed to create desktop entry for $name.${RESET}"
    return 1
  fi
}

# Setup all web applications
setup_webapps() {
  print_section "Setting up Web Applications"
  
  load_webapp_config
  
  echo -e "${ACTION} Creating Web Apps and desktop entries...${RESET}"

  # Ensure directories exist
  ensure_dir "$DESKTOP_DIR"
  ensure_dir "$ICON_DIR"

  local success_count=0
  local total_count=${#WEBAPPS[@]}

  # Process each webapp
  for entry in "${WEBAPPS[@]}"; do
    IFS="|" read -r name url icon <<<"$entry"
    
    echo -e "${ACTION} Processing: $name${RESET}"
    
    # Download icon and create desktop entry
    download_webapp_icon "$url" "$icon"
    if create_webapp_desktop_entry "$name" "$url" "$icon"; then
      ((success_count++))
    fi
  done

  echo -e "${OK} Web applications setup completed: $success_count/$total_count apps created.${RESET}"
  echo -e "${OK} Desktop entries: $DESKTOP_DIR${RESET}"
  echo -e "${OK} Icons: $ICON_DIR${RESET}"
  
  log_message "INFO" "Web applications setup completed ($success_count/$total_count)"
  return 0
}