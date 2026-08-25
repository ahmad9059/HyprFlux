#!/bin/bash
# https://github.com/ahmad9059/HyprFlux

clear

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Create Directory for Install Logs
if [ ! -d Install-Logs ]; then
  mkdir Install-Logs
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/01-Hyprland-Install-Scripts-$(date +%d-%H%M%S).log"

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
  echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......." | tee -a "$LOG"
  printf "\n%.0s" {1..2}
  exit 1
fi

# Check if PulseAudio package is installed
if pacman -Qq | grep -qw '^pulseaudio$'; then
  echo "$ERROR PulseAudio is detected as installed. Uninstall it first or edit install.sh on line 211 (execute_script 'pipewire.sh')." | tee -a "$LOG"
  printf "\n%.0s" {1..2}
  exit 1
fi

# Check if base-devel is installed
if pacman -Q base-devel &>/dev/null; then
  echo "base-devel is already installed."
else
  echo "$NOTE Install base-devel.........."

  if sudo pacman -S --noconfirm base-devel; then
    echo "👌 ${OK} base-devel has been installed successfully." | tee -a "$LOG"
  else
    echo "❌ $ERROR base-devel not found nor cannot be installed." | tee -a "$LOG"
    echo "$ACTION Please install base-devel manually before running this script... Exiting" | tee -a "$LOG"
    exit 1
  fi
fi

# install whiptails if detected not installed. Necessary for this version
if ! command -v whiptail >/dev/null; then
  echo "${NOTE} - whiptail is not installed. Installing..." | tee -a "$LOG"
  sudo pacman -S --noconfirm libnewt
  printf "\n%.0s" {1..1}
fi

clear

printf "\n%.0s" {1..2}
echo -e "\e[35m 
╦ ╦╦ ╦╔═╗╦═╗  ╔═╗╦  ╦ ╦═╗ ╦
╠═╣╚╦╝╠═╝╠╦╝  ╠╣ ║  ║ ║╔╩╦╝
╩ ╩ ╩ ╩  ╩╚═  ╚  ╩═╝╚═╝╩ ╚═
\e[0m"
printf "\n%.0s" {1..1}

# Welcome message using whiptail (for displaying information)
# HyprFlux: Skipped welcome dialog
echo "${INFO} [HyprFlux] Welcome to HyprFlux Arch-Hyprland Install Script!" | tee -a "$LOG"
echo "${NOTE} [HyprFlux] ATTENTION: Ensure system is updated before installation." | tee -a "$LOG"

# HyprFlux: Auto-proceed with installation
echo "${OK} [HyprFlux] Auto-proceeding with installation..." | tee -a "$LOG"

echo "👌 ${OK} 🇵🇰 ${MAGENTA}HyprFlux..${RESET} ${SKY_BLUE}lets continue with the installation...${RESET}" | tee -a "$LOG"

sleep 1
printf "\n%.0s" {1..1}

# install pciutils if detected not installed. Necessary for detecting GPU
if ! pacman -Qs pciutils >/dev/null; then
  echo "${NOTE} - pciutils is not installed. Installing..." | tee -a "$LOG"
  sudo pacman -S --noconfirm pciutils
  printf "\n%.0s" {1..1}
fi

# Path to the install-scripts directory
script_directory=install-scripts

# Function to execute a script if it exists and make it executable
execute_script() {
  local script="$1"
  local script_path="$script_directory/$script"
  if [ -f "$script_path" ]; then
    chmod +x "$script_path"
    if [ -x "$script_path" ]; then
      env "$script_path"
    else
      echo "Failed to make script '$script' executable."
    fi
  else
    echo "Script '$script' not found in '$script_directory'."
  fi
}

## Default values for the options (will be overwritten by preset file if available)
gtk_themes="OFF"
bluetooth="OFF"
thunar="OFF"
quickshell="OFF"
sddm="OFF"
sddm_theme="OFF"
xdph="OFF"
zsh="OFF"
pokemon="OFF"
rog="OFF"
dots="OFF"
input_group="OFF"
nvidia="OFF"
nouveau="OFF"

# Function to load preset file
load_preset() {
  if [ -f "$1" ]; then
    echo "✅ Loading preset: $1"
    source "$1"
  else
    echo "⚠️ Preset file not found: $1. Using default values."
  fi
}

# Check if --preset argument is passed
if [[ "$1" == "--preset" && -n "$2" ]]; then
  load_preset "$2"
fi

# HyprFlux: Auto-select yay as AUR helper
echo "${INFO} [HyprFlux] Checking if yay or paru is installed..." | tee -a "$LOG"
if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
  echo "${NOTE} [HyprFlux] Neither yay nor paru found. Auto-selecting yay..." | tee -a "$LOG"
  aur_helper="yay"
else
  echo "${NOTE} [HyprFlux] AUR helper is already installed. Skipping selection." | tee -a "$LOG"
fi

# List of services to check for active login managers
services=("gdm.service" "gdm3.service" "lightdm.service" "lxdm.service")

# Function to check if any login services are active
check_services_running() {
  active_services=() # Array to store active services
  for svc in "${services[@]}"; do
    if systemctl is-active --quiet "$svc"; then
      active_services+=("$svc")
    fi
  done

  if [ ${#active_services[@]} -gt 0 ]; then
    return 0
  else
    return 1
  fi
}

if check_services_running; then
  active_list=$(printf "%s\n" "${active_services[@]}")
  echo "${WARN} [HyprFlux] Active non-SDDM login manager detected: $active_list" | tee -a "$LOG"
  echo "${NOTE} [HyprFlux] SDDM installation options may be affected." | tee -a "$LOG"
fi

# Check if NVIDIA GPU is detected
nvidia_detected=false
if lspci | grep -i "nvidia" &>/dev/null; then
  nvidia_detected=true
  echo "${NOTE} [HyprFlux] NVIDIA GPU detected - will configure if selected" | tee -a "$LOG"
fi

# Check if user is in the input group (needed for Waybar keyboard-state)
input_group_detected=false
if ! groups "$(whoami)" | grep -q '\binput\b'; then
  input_group_detected=true
  echo "${NOTE} [HyprFlux] User not in input group - will add if selected" | tee -a "$LOG"
fi

# HyprFlux: Pre-selected installation options (no whiptail dialogs)
echo "${INFO} [HyprFlux] Using pre-configured installation options..." | tee -a "$LOG"

# Pre-selected options for HyprFlux
selected_options="sddm bluetooth thunar xdph zsh dots"

# Add nvidia options if detected
if [ "$nvidia_detected" == "true" ]; then
  selected_options="nvidia nouveau $selected_options"
  echo "${NOTE} [HyprFlux] NVIDIA GPU detected - adding nvidia configuration" | tee -a "$LOG"
fi

# Add input_group if needed
if [ "$input_group_detected" == "true" ]; then
  selected_options="input_group $selected_options"
  echo "${NOTE} [HyprFlux] Adding user to input group" | tee -a "$LOG"
fi

# Convert to array
IFS=' ' read -r -a options <<< "$selected_options"

echo "${OK} [HyprFlux] Selected options:" | tee -a "$LOG"
for option in "${options[@]}"; do
  echo "  - $option" | tee -a "$LOG"
done

echo "${OK} [HyprFlux] Proceeding with HyprFlux Hyprland Installation..." | tee -a "$LOG"
printf "\n%.0s" {1..1}

# Ensuring base-devel is installed
execute_script "00-base.sh"
sleep 1
execute_script "pacman.sh"
sleep 1

# Custom HyprFlux Scripts (local, merged layout)
# This install.sh now lives inside the HyprFlux repo: <repo>/Arch-Hyprland/
HYPRFLUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-scripts"
cp "$HYPRFLUX_DIR/scripts/zsh.sh" "$INSTALL_SCRIPTS_DIR/zsh.sh"
chmod +x "$INSTALL_SCRIPTS_DIR/zsh.sh"
# NOTE: replace_reads.sh is no longer needed - Hyprland-Dots is merged and
# its scripts are already pre-patched for non-interactive installation.
bash "$HYPRFLUX_DIR/scripts/initial.sh" || echo "${WARN} [HyprFlux] initial.sh had issues — continuing" | tee -a "$LOG"
sleep 1

# Execute AUR helper script after other installations if applicable
if [ "$aur_helper" == "paru" ]; then
  execute_script "paru.sh"
elif [ "$aur_helper" == "yay" ]; then
  execute_script "yay.sh"
fi

sleep 1

# Run the Hyprland related scripts
echo "${INFO} Installing ${SKY_BLUE}HyprFlux Hyprland additional packages...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "01-hypr-pkgs.sh"

echo "${INFO} Installing ${SKY_BLUE}pipewire and pipewire-audio...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "pipewire.sh"

echo "${INFO} Installing ${SKY_BLUE}necessary fonts...${RESET}" | tee -a "$LOG"
sleep 1
execute_script "fonts.sh"

echo "${INFO} Installing ${SKY_BLUE}Hyprland...${RESET}"
sleep 1
execute_script "hyprland.sh"

# Clean up the selected options (remove quotes and trim spaces)
selected_options=$(echo "$selected_options" | tr -d '"' | tr -s ' ')

# Convert selected options into an array (splitting by spaces)
IFS=' ' read -r -a options <<<"$selected_options"

# Loop through selected options
for option in "${options[@]}"; do
  case "$option" in
  sddm)
    if check_services_running; then
      echo "${WARN} [HyprFlux] Active login manager detected - skipping SDDM" | tee -a "$LOG"
    else
      echo "${INFO} Installing and configuring ${SKY_BLUE}SDDM...${RESET}" | tee -a "$LOG"
      execute_script "sddm.sh"
    fi
    ;;
  nvidia)
    echo "${INFO} Configuring ${SKY_BLUE}nvidia stuff${RESET}" | tee -a "$LOG"
    execute_script "nvidia.sh"
    ;;
  nouveau)
    echo "${INFO} blacklisting ${SKY_BLUE}nouveau${RESET}"
    execute_script "nvidia_nouveau.sh" | tee -a "$LOG"
    ;;
  input_group)
    echo "${INFO} Adding user into ${SKY_BLUE}input group...${RESET}" | tee -a "$LOG"
    execute_script "InputGroup.sh"
    ;;
  xdph)
    echo "${INFO} Installing ${SKY_BLUE}xdg-desktop-portal-hyprland...${RESET}" | tee -a "$LOG"
    execute_script "xdph.sh"
    ;;
  bluetooth)
    echo "${INFO} Configuring ${SKY_BLUE}Bluetooth...${RESET}" | tee -a "$LOG"
    execute_script "bluetooth.sh"
    ;;
  thunar)
    echo "${INFO} Installing ${SKY_BLUE}Thunar file manager...${RESET}" | tee -a "$LOG"
    execute_script "thunar.sh"
    execute_script "thunar_default.sh"
    ;;
  zsh)
    echo "${INFO} Installing ${SKY_BLUE}zsh with Oh-My-Zsh...${RESET}" | tee -a "$LOG"
    execute_script "zsh.sh"
    ;;
  rog)
    echo "${INFO} Installing ${SKY_BLUE}ROG laptop packages...${RESET}" | tee -a "$LOG"
    execute_script "rog.sh"
    ;;
  dots)
    echo "${INFO} Installing pre-configured ${SKY_BLUE}HyprFlux Hyprland dotfiles...${RESET}" | tee -a "$LOG"
    execute_script "dotfiles-main.sh"
    ;;
  *)
    echo "Unknown option: $option" | tee -a "$LOG"
    ;;
  esac
done

sleep 1
# copy fastfetch config if arch.png is not present
if [ ! -f "$HOME/.config/fastfetch/arch.png" ]; then
  cp -r assets/fastfetch "$HOME/.config/"
fi

clear

# final check essential packages if it is installed
execute_script "02-Final-Check.sh"

printf "\n%.0s" {1..1}

# Check if hyprland or hyprland-git is installed
if pacman -Q hyprland &>/dev/null || pacman -Q hyprland-git &>/dev/null; then
  printf "\n ${OK} 👌 Hyprland is installed. However, some essential packages may not be installed. Please see above!"
  printf "\n${CAT} Ignore this message if it states ${YELLOW}All essential packages${RESET} are installed as per above\n"
  sleep 2
  printf "\n%.0s" {1..2}

  printf "${SKY_BLUE}Thank you${RESET} 🫰 for using 🇵🇰 ${MAGENTA}HyprFlux's Hyprland Dots${RESET}. ${YELLOW}Enjoy and Have a good day!${RESET}"
  printf "\n%.0s" {1..2}

  printf "\n${NOTE} You can start Hyprland by typing ${SKY_BLUE}Hyprland${RESET} (IF SDDM is not installed) (note the capital H!).\n"
  printf "\n${NOTE} However, it is ${YELLOW}highly recommended to reboot${RESET} your system.\n\n"

  while true; do
    echo -n "${CAT} Would you like to reboot now? (y/n): "
    # HyprFlux: auto-answer no (HyprFlux/install.sh handles the reboot prompt)
    HYP="n"
    HYP=$(echo "$HYP" | tr '[:upper:]' '[:lower:]')

    if [[ "$HYP" == "y" || "$HYP" == "yes" ]]; then
      echo "${INFO} Rebooting now..."
      systemctl reboot
      break
    elif [[ "$HYP" == "n" || "$HYP" == "no" ]]; then
      echo "👌 ${OK} You chose NOT to reboot"
      printf "\n%.0s" {1..1}
      # Check if NVIDIA GPU is present
      if lspci | grep -i "nvidia" &>/dev/null; then
        echo "${INFO} HOWEVER ${YELLOW}NVIDIA GPU${RESET} detected. Reminder that you must REBOOT your SYSTEM..."
        printf "\n%.0s" {1..1}
      fi
      break
    else
      echo "${WARN} Invalid response. Please answer with 'y' or 'n'."
    fi
  done
else
  # Print error message if neither package is installed
  printf "\n${WARN} Hyprland is NOT installed. Please check 00_CHECK-time_installed.log and other files in the Install-Logs/ directory..."
  printf "\n%.0s" {1..3}
  exit 1
fi

printf "\n%.0s" {1..2}
