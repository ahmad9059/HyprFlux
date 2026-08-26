#!/usr/bin/env bash
# User interaction helpers extracted from copy.sh. Each helper echoes state or sets
# globals deliberately to minimize side effects.

# Detect keyboard layout via localectl or setxkbmap.
prompt_detect_layout() {
  if command -v localectl >/dev/null 2>&1; then
    local layout
    layout=$(localectl status --no-pager | awk '/X11 Layout/ {print $3}')
    [ -n "$layout" ] && { echo "$layout"; return; }
  fi
  if command -v setxkbmap >/dev/null 2>&1; then
    local layout
    layout=$(setxkbmap -query | awk '/layout/ {print $2}')
    [ -n "$layout" ] && { echo "$layout"; return; }
  fi
  echo "(unset)"
}

# Confirm or set keyboard layout; writes to UserConfigs/user-settings.lua.
prompt_keyboard_layout() {
  local layout="$1"
  local log="$2"
  # HyprFlux: Auto-accept detected keyboard layout
  if [ "$layout" = "(unset)" ]; then
    layout="us"
  fi
  printf "${NOTE:-[NOTE]} [HyprFlux] Auto-configuring keyboard layout: ${MAGENTA:-}$layout${RESET:-}\n"
  sed -i "s/^        kb_layout = .*/        kb_layout = \"$layout\",/" config/hypr/UserConfigs/user-settings.lua
  echo "${OK:-[OK]} [HyprFlux] kb_layout $layout configured in user-settings.lua." 2>&1 | tee -a "$log"
}

# Prompt for resolution choice; echoes "< 1440p" or "≥ 1440p".
prompt_resolution_choice() {
  local choice
  while true; do
    echo "${INFO:-[INFO]} Select monitor resolution for scaling:"
    echo "  1) < 1440p   (lower DPI; smaller displays)"
    echo "  2) ≥ 1440p   (default; 1440p/2k/4k)"

    if ! read -r -p "${CAT} Enter the number of your choice (1 or 2): " choice </dev/tty; then
      echo "${ERROR} Unable to read input (tty unavailable)."
      continue
    fi
    echo "${INFO:-[INFO]} You entered: '$choice'"
    case "$choice" in
      1) echo "< 1440p"; return ;;
      2) echo "≥ 1440p"; return ;;
      *) echo "${ERROR} Invalid choice. Please enter 1 for < 1440p or 2 for ≥ 1440p." ;;
    esac
  done
}

# Prompt for 12H clock; sets waybar/hyprlock/SDDM changes when accepted.
prompt_clock_12h() {
  local log="$1"
  # HyprFlux: Auto-select 12H (AM/PM) format
  echo "${NOTE:-[NOTE]} [HyprFlux] Configuring 12H (AM/PM) clock format..." 2>&1 | tee -a "$log"

  # waybar clocks
  sed -i 's#^\(\s*\)//\("format": " {:%I:%M %p}",\) #\1\2 #g' config/waybar/Modules 2>&1 | tee -a "$log"
  sed -i 's#^\(\s*\)\("format": " {:%H:%M:%S}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
  sed -i 's#^\(\s*\)\("format": "  {:%H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
  sed -i 's#^\(\s*\)//\("format": "{:%I:%M %p - %d/%b}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
  sed -i 's#^\(\s*\)\("format": "{:%H:%M - %d/%b}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
  sed -i 's#^\(\s*\)//\("format": "{:%B | %a %d, %Y | %I:%M %p}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
  sed -i 's#^\(\s*\)\("format": "{:%B | %a %d, %Y | %H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
  sed -i 's#^\(\s*\)//\("format": "{:%A, %I:%M %P}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$log"
  sed -i 's#^\(\s*\)\("format": "{:%a %d | %H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$log"

  # hyprlock
  local HYPRLOCK_FILE="config/hypr/hyprlock.conf"
  if [ ! -f "$HYPRLOCK_FILE" ] && [ -f "config/hypr/hyprlock-1080p.conf" ]; then
    HYPRLOCK_FILE="config/hypr/hyprlock-1080p.conf"
  fi
  if [ -f "$HYPRLOCK_FILE" ]; then
    sed -i 's/^\s*text = cmd\[update:1000\] echo "\$(date +"%H")"/# &/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
    sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo "\$(date +"%I")" #AM\/PM/\1    text = cmd[update:1000] echo "$(date +"%I")" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
    sed -i 's/^\s*text = cmd\[update:1000\] echo "\$(date +"%S")"/# &/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
    sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo "\$(date +"%S %p")" #AM\/PM/\1    text = cmd[update:1000] echo "$(date +"%S %p")" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
  fi

  echo "${OK:-[OK]} [HyprFlux] 12H (AM/PM) clock format configured." 2>&1 | tee -a "$log"
}

apply_sddm_12h_format() {
  local sddm_directory="$1"
  local log="$2"
  if [ -d "$sddm_directory" ]; then
    echo "Editing ${SKY_BLUE}$sddm_directory${RESET} to 12H format" 2>&1 | tee -a "$log"
    if ! sudo -n sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log"; then
      echo "${WARN:-[WARN]} Skipping SDDM 12H edit (sudo password required)." 2>&1 | tee -a "$log"
      return
    fi
    sudo -n sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log" || true
  fi
}

apply_sddm_12h_format_sequoia() {
  local sddm_directory="$1"
  local log="$2"
  if [ -d "$sddm_directory" ]; then
    echo "${YELLOW}sddm sequoia_2${RESET} theme exists. Editing to 12H format" 2>&1 | tee -a "$log"
    if ! sudo -n sed -i 's|^clockFormat="HH:mm"|## clockFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log"; then
      echo "${WARN:-[WARN]} Skipping sequoia SDDM 12H edit (sudo password required)." 2>&1 | tee -a "$log"
      return
    fi
    if ! grep -q 'clockFormat="hh:mm AP"' "$sddm_directory/theme.conf"; then
      sudo -n sed -i '/^clockFormat=/a clockFormat="hh:mm AP"' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log" || true
    fi
    echo "${OK} 12H format set to SDDM successfully." 2>&1 | tee -a "$log"
  fi
}


# Express upgrade confirmation; may set EXPRESS_MODE=1.
prompt_express_upgrade() {
  local express_supported="$1"
  local log="$2"
  # HyprFlux: Skip express prompt, use standard install
  echo "${NOTE:-[NOTE]} [HyprFlux] Continuing with standard install..." 2>&1 | tee -a "$log"
}
