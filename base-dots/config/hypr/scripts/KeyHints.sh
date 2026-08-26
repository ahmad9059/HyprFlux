#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Quick cheat sheet — curated from the actual config
# (configs/keybinds.lua + UserConfigs/user-keybinds.lua + UserConfigs/laptops.lua)

# GDK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

# Kill rofi/yad if running
if pidof rofi >/dev/null; then pkill rofi; fi
if pidof yad >/dev/null; then pkill yad; fi

# Launch yad with the keybinds
GDK_BACKEND=$BACKEND yad \
  --center \
  --title="HyprFlux Quick Cheat Sheet" \
  --no-buttons \
  --list \
  --column="Key:" \
  --column="Description:" \
  --timeout-indicator=bottom \
  "CTRL + ALT + Delete"    "Exit Hyprland" \
  "CTRL + ALT + L"         "Lock screen" \
  "CTRL + ALT + P"         "Power menu" \
  "SUPER + N"              "Notifications panel (swaync)" \
  "SUPER + SHIFT + E"      "HyprFlux Quick Settings menu" \
  "SUPER + SHIFT + H"      "Cheat sheet (this)" \
  "SUPER + Q"              "Close active window" \
  "SUPER + SHIFT + Q"      "Kill active process" \
  "" "" \
  "═════ APPS ═════" "" \
  "SUPER + RETURN"         "Terminal (kitty)" \
  "SUPER + D"              "App launcher (rofi)" \
  "SUPER + F"              "File manager (thunar)" \
  "SUPER + B"              "Firefox" \
  "SUPER + K"              "Kdenlive" \
  "SUPER + R"              "Foliate (ebook reader)" \
  "SUPER + V"              "Clipboard manager" \
  "SUPER + C"              "Visual Studio Code" \
  "SUPER + O"              "Obsidian" \
  "SUPER + S"              "Spotify" \
  "SUPER + X"              "Vesktop (Discord)" \
  "SUPER + T"              "Telegram" \
  "SUPER + M"              "Free Download Manager" \
  "SUPER + E"              "Tmuxifier projects" \
  "" "" \
  "═════ WINDOWS ═════" "" \
  "SUPER + SPACE"          "Toggle floating" \
  "SUPER + ALT + SPACE"    "All windows floating" \
  "SUPER + SHIFT + F"      "Fullscreen" \
  "SUPER + CTRL + F"       "Fake fullscreen (maximized)" \
  "SUPER + SHIFT + RETURN" "Dropdown terminal" \
  "SUPER + P"              "Pseudotile" \
  "SUPER + arrows"         "Move focus" \
  "SUPER + SHIFT + arrows" "Resize window" \
  "SUPER + CTRL + arrows"  "Move window" \
  "SUPER + ALT + arrows"   "Swap windows" \
  "SUPER + LMB / RMB"      "Drag-move / drag-resize window" \
  "SUPER + I"              "Master: add to master" \
  "SUPER + CTRL + D"       "Master: remove master" \
  "SUPER + CTRL + RETURN"  "Master: swap with master" \
  "SUPER + J / K"          "Cycle next / previous window" \
  "" "" \
  "═════ WORKSPACES ═════" "" \
  "SUPER + 1..0"           "Switch to workspace 1-10" \
  "SUPER + SHIFT + 1..0"   "Move window to workspace" \
  "SUPER + CTRL + 1..0"    "Move window to workspace (silent)" \
  "SUPER + U"              "Toggle special workspace (nyx)" \
  "SUPER + SHIFT + U"      "Move window to special (nyx)" \
  "SUPER + tab"            "Next workspace (monitor)" \
  "SUPER + SHIFT + tab"    "Previous workspace (monitor)" \
  "SUPER + wheel"          "Cycle through workspaces" \
  "" "" \
  "═════ SCREENSHOTS ═════" "" \
  "SUPER + Print"          "Screenshot (now)" \
  "SUPER + SHIFT + Print"  "Screenshot (area)" \
  "SUPER + CTRL + Print"   "Screenshot (5s delay)" \
  "SUPER + CTRL + SHIFT + Print" "Screenshot (10s delay)" \
  "ALT + Print"            "Screenshot (active window)" \
  "SUPER + SHIFT + S"      "Screenshot (swappy)" \
  "SUPER + F6"             "Screenshot (laptop, now)" \
  "SUPER + SHIFT + F6"     "Screenshot (laptop, area)" \
  "" "" \
  "═════ MEDIA & HARDWARE ═════" "" \
  "XF86AudioRaise/Lower"   "Volume up / down" \
  "XF86AudioMute"          "Mute audio" \
  "XF86AudioMicMute"       "Mute microphone" \
  "XF86AudioPlay/Pause"    "Play / pause media" \
  "XF86AudioNext/Prev"     "Next / previous track" \
  "XF86AudioStop"          "Stop playback" \
  "XF86MonBrightnessUp/Down" "Screen brightness (Fn+F8/F7)" \
  "XF86KbdBrightnessUp/Down" "Keyboard backlight" \
  "XF86TouchpadToggle"     "Toggle touchpad" \
  "XF86Rfkill"             "Airplane mode" \
  "XF86Sleep"              "Suspend" \
  "XF86Launch1"            "ASUS Armory Crate" \
  "XF86Launch3"            "Keyboard RGB profile (FN+F4)" \
  "XF86Launch4"            "Fan profiles (FN+F5)" \
  "" "" \
  "═════ FEATURES ═════" "" \
  "SUPER + SHIFT + G"      "Game mode toggle" \
  "SUPER + SHIFT + O"      "Toggle blur settings" \
  "SUPER + SHIFT + L"      "Cycle layout (Dwindle/Master/Scrolling)" \
  "SUPER + SHIFT + R"      "Refresh waybar, swaync, rofi" \
  "SUPER + SHIFT + W"      "Wallpaper select / effects" \
  "CTRL + ALT + W"         "Random wallpaper" \
  "SUPER + SHIFT + K"      "Search keybinds (rofi)" \
  "SUPER + SHIFT + A"      "Animations menu" \
  "SUPER + SHIFT + M"      "Online music (rofi)" \
  "SUPER + SHIFT + D"      "Sync dotfiles" \
  "SUPER + SHIFT + B"      "Sync blog" \
  "SUPER + SHIFT + N"      "Obsidian note generator" \
  "SUPER + SHIFT + P"      "Color picker (hyprpicker)" \
  "SUPER + SHIFT + T"      "Toggle tuned daemon" \
  "SUPER + CTRL + C"       "Calculator (rofi)" \
  "SUPER + ALT + E"        "Emoji menu" \
  "SUPER + ALT + mouse"    "Zoom in / out (magnifier)" \
  "SUPER + CTRL + O"       "Toggle opacity (active window)" \
  "SUPER + CTRL + ALT + B" "Toggle waybar (hide/show)" \
  "" "" \
  "" "More at ~/.config/hypr/UserConfigs and UserScripts"
