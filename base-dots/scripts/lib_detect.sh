#!/usr/bin/env bash
# Detection and environment adjustment helpers shared by copy.sh.

# Nvidia tweaks: uncomments envs and adjusts hardware cursor setting.
detect_nvidia_adjust() {
  local log="$1"
  if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    echo "${INFO:-[INFO]} Nvidia GPU detected. Setting up proper env's and configs (Lua config)" 2>&1 | tee -a "$log" || true
    sed -i 's/^-- hl.env("LIBVA_DRIVER_NAME", "nvidia")/hl.env("LIBVA_DRIVER_NAME", "nvidia")/' config/hypr/UserConfigs/env-variables.lua
    sed -i 's/^-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")/hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")/' config/hypr/UserConfigs/env-variables.lua
    sed -i 's/^-- hl.env("NVD_BACKEND", "direct")/hl.env("NVD_BACKEND", "direct")/' config/hypr/UserConfigs/env-variables.lua
    sed -i 's/^-- hl.env("GSK_RENDERER", "ngl")/hl.env("GSK_RENDERER", "ngl")/' config/hypr/UserConfigs/env-variables.lua
    sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2,/\1 1,/' config/hypr/UserConfigs/user-settings.lua
  fi
}

# VM tweaks: enable software renderer envs and virtual monitor defaults.
detect_vm_adjust() {
  local log="$1"
  if hostnamectl | grep -q 'Chassis: vm'; then
    echo "${INFO:-[INFO]} System is running in a virtual machine. Setting up proper env's and configs (Lua config)" 2>&1 | tee -a "$log" || true
    sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2,/\1 1,/' config/hypr/UserConfigs/user-settings.lua
    sed -i 's/^-- hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")/hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")/' config/hypr/UserConfigs/env-variables.lua
    sed -i 's/^-- hl.monitor({ output = "Virtual-1", mode = "1920x1080@60", position = "auto", scale = 1 })/hl.monitor({ output = "Virtual-1", mode = "1920x1080@60", position = "auto", scale = 1 })/' config/hypr/monitors.lua
  fi
}

# NixOS tweaks: ensure polkit overlay is enabled and default disabled.
detect_nixos_adjust() {
  local log="$1"
  if hostnamectl | grep -q 'Operating System: NixOS'; then
    echo "${INFO:-[INFO]} NixOS Distro Detected. Setting up proper env's and configs." 2>&1 | tee -a "$log" || true
    # HyprFlux: Polkit handled by scripts/Polkit.sh (Lua startup-apps.lua)
  fi
}

# Decide waybar config/style based on chassis type. Echoes chosen config path.
detect_waybar_config() {
  if hostnamectl | grep -q 'Chassis: desktop'; then
    echo "desktop"
  else
    echo "laptop"
  fi
}
