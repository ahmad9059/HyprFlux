#!/bin/bash
# 💫 https://github.com/ahmad9059/HyprFlux 💫 #
# Hyprland Packages #

# edit your packages desired here. 
# WARNING! If you remove packages here, dotfiles may not work properly.
# and also, ensure that packages are present in AUR and official Arch Repo

# add packages wanted here
Extra=(

)

hypr_package=( 
  #aylurs-gtk-shell
  bc
  cliphist
  curl 
  grim 
  gvfs 
  gvfs-mtp
  hyprpolkitagent
  imagemagick
  inxi 
  jq
  kitty
  kvantum
  libspng
  nano  
  network-manager-applet 
  pamixer 
  pavucontrol
  playerctl
  python-requests
  python-pyquery
  qt5ct
  qt6ct
  qt6-svg
  rofi
  slurp 
  swappy 
  swaync 
  swww
  unzip # needed later
  # NOTE: waybar removed here — HyprFlux requires waybar-git (chaotic-aur)
  # for workspace-click Lua dispatch (hl.dsp); installed in hypr_aur_package.
  wget
  wl-clipboard
  wlogout
  xdg-user-dirs
  xdg-utils 
  yad
)

# the following packages can be deleted. however, dotfiles may not work properly
hypr_package_2=(
  brightnessctl 
  btop
  cava
  loupe
  fastfetch
  gnome-system-monitor
  mousepad 
  mpv
  mpv-mpris 
  nvtop
  nwg-look
  nwg-displays
  pacman-contrib
  qalculate-gtk
  yt-dlp

  # ── HyprFlux required (was modules/03-packages.sh — merged here so the
  #    base installer is the SINGLE package step) ──
  foot lsd bat neovim firefox tmux yazi zoxide
  qt6-5compat chromium npm plymouth rclone lazygit github-cli
  networkmanager power-profiles-daemon

  # ── HyprFlux default apps (was modules/17-optional-packages.sh — no
  #    longer optional; everything installs in this one pass) ──
  alacritty tldr
  obs-studio vlc luacheck luarocks hyprpicker
  obsidian noto-fonts-emoji tuned
  ttf-noto-nerd noto-fonts
  kdenlive
)

# List of packages to uninstall as it conflicts some packages
uninstall=(
  aylurs-gtk-shell
  dunst
  cachyos-hyprland-settings
  mako
  rofi
  rofi-lbonn-wayland
  rofi-lbonn-wayland-git
)

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi



# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hypr-pkgs.log"

# conflicting packages removal
overall_failed=0
printf "\n%s - ${SKY_BLUE}Removing some packages${RESET} as it conflicts with HyprFlux Dots \n" "${NOTE}"
for PKG in "${uninstall[@]}"; do
  uninstall_package "$PKG" 2>&1 | tee -a "$LOG"
  if [ $? -ne 0 ]; then
    overall_failed=1
  fi
done

if [ $overall_failed -ne 0 ]; then
  echo -e "${ERROR} Some packages failed to uninstall. Please check the log."
fi

printf "\n%.0s" {1..1}

# ── AUR packages (was modules/03, 16, 17 — merged into one step) ──
# awww-git:      animated wallpaper daemon (awww-daemon, Wallpaper*.sh)
# mpvpaper:      video wallpaper support (WallpaperSelect.sh)
# waybar-git:    REQUIRED for workspace-click Lua dispatch (hl.dsp)
hypr_aur_package=(
  awww-git mpvpaper waybar-git
  visual-studio-code-bin 64gram-desktop-bin vesktop
  foliate localsend-bin tuxedo-bin
  claude-code opencode-bin openai-codex-bin
  freedownloadmanager
)

# Installation of main components
printf "\n%s - Installing ${SKY_BLUE}HyprFlux necessary packages${RESET} .... \n" "${NOTE}"

for PKG1 in "${hypr_package[@]}" "${hypr_package_2[@]}" "${Extra[@]}"; do
  install_package "$PKG1" "$LOG"
done

printf "\n%s - Installing ${SKY_BLUE}HyprFlux AUR packages${RESET} .... \n" "${NOTE}"

for PKG2 in "${hypr_aur_package[@]}"; do
  install_package "$PKG2" "$LOG"
done

printf "\n%.0s" {1..2}
