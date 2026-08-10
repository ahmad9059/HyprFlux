#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Rofi menu for HyprFlux Quick Settings (SUPER SHIFT E)

# Modify this config file for default terminal and EDITOR
config_file="$HOME/.config/hypr/UserConfigs/user-defaults.lua"

# extract string values from the Lua defaults module (Hyprland >= 0.55)
# $1 = grep pattern, $2 = sed anchor (defaults to $1)
get_lua_str() {
  local grep_pat="$1" anchor="${2:-$1}"
  grep "$grep_pat" "$config_file" | head -1 | sed "s/.*${anchor}\"\([^\"]*\)\".*/\1/"
}
term=$(get_lua_str 'term = ')
files=$(get_lua_str 'files = ')
edit="${EDITOR:-$(get_lua_str 'edit = ' 'or ')}"
# ##################################### #

# variables
configs="$HOME/.config/hypr/configs"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
# msg=' ⁉️ Choose what to do ⁉️'
scriptsDir="$HOME/.config/hypr/scripts"
UserScripts="$HOME/.config/hypr/UserScripts"

# Function to display the menu options without numbers
menu() {
  cat <<EOF
view/edit User Defaults
view/edit ENV variables
view/edit Window Rules
view/edit User Keybinds
view/edit User Settings
view/edit Startup Apps
view/edit Decorations
view/edit Animations
view/edit Laptop Keybinds
view/edit Default Keybinds
Choose Kitty Terminal Theme
Configure Monitors (nwg-displays)
Configure Workspace Rules (nwg-displays)
GTK Settings (nwg-look)
QT Apps Settings (qt6ct)
QT Apps Settings (qt5ct)
Choose Hyprland Animations
Choose Monitor Profiles
Choose Rofi Themes
Search for Keybinds
Toggle Game Mode
Switch Dark-Light Theme
EOF
}

# Main function to handle menu selection
main() {
  choice=$(menu | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

  # Map choices to corresponding files (Lua modules, Hyprland >= 0.55)
  case "$choice" in
  "view/edit User Defaults") file="$UserConfigs/user-defaults.lua" ;;
  "view/edit ENV variables") file="$UserConfigs/env-variables.lua" ;;
  "view/edit Window Rules") file="$UserConfigs/window-rules.lua" ;;
  "view/edit User Keybinds") file="$UserConfigs/user-keybinds.lua" ;;
  "view/edit User Settings") file="$UserConfigs/user-settings.lua" ;;
  "view/edit Startup Apps") file="$UserConfigs/startup-apps.lua" ;;
  "view/edit Decorations") file="$UserConfigs/user-decorations.lua" ;;
  "view/edit Animations") file="$UserConfigs/user-animations.lua" ;;
  "view/edit Laptop Keybinds") file="$UserConfigs/laptops.lua" ;;
  "view/edit Default Keybinds") file="$configs/keybinds.lua" ;;
  "Choose Kitty Terminal Theme") $scriptsDir/Kitty_themes.sh ;;
  "Configure Monitors (nwg-displays)")
    if ! command -v nwg-displays &>/dev/null; then
      notify-send -i "dialog-error" "E-R-R-O-R" "Install nwg-displays first"
      exit 1
    fi
    nwg-displays
    ;;
  "Configure Workspace Rules (nwg-displays)")
    if ! command -v nwg-displays &>/dev/null; then
      notify-send -i "dialog-error" "E-R-R-O-R" "Install nwg-displays first"
      exit 1
    fi
    nwg-displays
    ;;
  "GTK Settings (nwg-look)")
    if ! command -v nwg-look &>/dev/null; then
      notify-send -i "dialog-error" "E-R-R-O-R" "Install nwg-look first"
      exit 1
    fi
    nwg-look
    ;;
  "QT Apps Settings (qt6ct)")
    if ! command -v qt6ct &>/dev/null; then
      notify-send -i "dialog-error" "E-R-R-O-R" "Install qt6ct first"
      exit 1
    fi
    qt6ct
    ;;
  "QT Apps Settings (qt5ct)")
    if ! command -v qt5ct &>/dev/null; then
      notify-send -i "dialog-error" "E-R-R-O-R" "Install qt5ct first"
      exit 1
    fi
    qt5ct
    ;;
  "Choose Hyprland Animations") $scriptsDir/Animations.sh ;;
  "Choose Monitor Profiles") $scriptsDir/MonitorProfiles.sh ;;
  "Choose Rofi Themes") $scriptsDir/RofiThemeSelector.sh ;;
  "Search for Keybinds") $scriptsDir/KeyBinds.sh ;;
  "Toggle Game Mode") $scriptsDir/GameMode.sh ;;
  "Switch Dark-Light Theme") $scriptsDir/DarkLight.sh ;;
  *) return ;; # Do nothing for invalid choices
  esac

  # Open the selected file in the terminal with the text editor
  if [ -n "$file" ]; then
    $term -e $edit "$file"
  fi
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

main

