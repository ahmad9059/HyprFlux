#!/bin/bash
# ============================================================
# HyprFlux - Bypass Whiptail Dialogs Script
# https://github.com/ahmad9059/HyprFlux
# ============================================================
# Modifies Arch-Hyprland install.sh to skip interactive whiptail
# dialogs and use pre-selected options for fully automated installation

set -e

# ===========================
# Color-coded status labels
# ===========================
ERROR="$(tput setaf 1)[HyprFlux] [ERROR]$(tput sgr0)"
WARN="$(tput setaf 3)[HyprFlux] [WARN]$(tput sgr0)"
OK="$(tput setaf 2)[HyprFlux] [OK]$(tput sgr0)"
NOTE="$(tput setaf 6)[HyprFlux] [NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[HyprFlux] [INFO]$(tput sgr0)"
RESET="$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
CYAN="$(tput setaf 6)"

echo ""
echo "${CYAN}============================================${RESET}"
echo "${MAGENTA}  HyprFlux Dialog Bypass${RESET}"
echo "${CYAN}============================================${RESET}"
echo ""

# ===========================
# Target file
# ===========================
ARCH_HYPRLAND_DIR="${ARCH_HYPRLAND_DIR:-$HOME/Arch-Hyprland}"
INSTALL_SH="$ARCH_HYPRLAND_DIR/install.sh"

if [ ! -f "$INSTALL_SH" ]; then
  echo "${ERROR} Arch-Hyprland install.sh not found at: $INSTALL_SH${RESET}"
  exit 1
fi

echo "${INFO} Applying HyprFlux automated dialog bypass...${RESET}"

# ===========================
# 1. Remove Welcome whiptail msgbox
# ===========================
sed -i '/^whiptail --title "HyprFlux Arch-Hyprland (2025) Install Script"/,/15 80$/c\
# HyprFlux: Skipped welcome dialog\
echo "${INFO} [HyprFlux] Welcome to HyprFlux Arch-Hyprland Install Script!" | tee -a "$LOG"\
echo "${NOTE} [HyprFlux] ATTENTION: Ensure system is updated before installation." | tee -a "$LOG"' "$INSTALL_SH"

echo "${OK} Bypassed welcome dialog${RESET}"

# ===========================
# 2. Remove "Proceed with Installation?" yesno dialog
# ===========================
sed -i '/^# Ask if the user wants to proceed$/,/^fi$/c\
# HyprFlux: Auto-proceed with installation\
echo "${OK} [HyprFlux] Auto-proceeding with installation..." | tee -a "$LOG"' "$INSTALL_SH"

echo "${OK} Bypassed proceed confirmation dialog${RESET}"

# ===========================
# 3. Auto-select YAY as AUR helper
# ===========================
sed -i '/^# Check if yay or paru is installed$/,/^fi$/c\
# HyprFlux: Auto-select yay as AUR helper\
echo "${INFO} [HyprFlux] Checking if yay or paru is installed..."\
if ! command -v yay \&>/dev/null \&\& ! command -v paru \&>/dev/null; then\
  echo "${NOTE} [HyprFlux] Neither yay nor paru found. Auto-selecting yay..." | tee -a "$LOG"\
  aur_helper="yay"\
else\
  echo "${NOTE} [HyprFlux] AUR helper is already installed. Skipping selection."\
fi' "$INSTALL_SH"

echo "${OK} Auto-selected yay as AUR helper${RESET}"

# ===========================
# 4. Remove NVIDIA GPU detected msgbox
# ===========================
sed -i 's/whiptail --title "NVIDIA GPU Detected" --msgbox.*$/echo "${NOTE} [HyprFlux] NVIDIA GPU detected - will configure if selected" | tee -a "$LOG"/' "$INSTALL_SH"

echo "${OK} Bypassed NVIDIA detection dialog${RESET}"

# ===========================
# 5. Remove Input Group msgbox
# ===========================
sed -i 's/whiptail --title "Input Group" --msgbox.*$/echo "${NOTE} [HyprFlux] User not in input group - will add if selected" | tee -a "$LOG"/' "$INSTALL_SH"

echo "${OK} Bypassed input group dialog${RESET}"

# ===========================
# 6. Remove Active Login Manager msgbox
# ===========================
sed -i '/whiptail --title "Active non-SDDM login manager(s) detected"/,/23 80$/c\
    echo "${WARN} [HyprFlux] Active non-SDDM login manager detected: $active_list" | tee -a "$LOG"\
    echo "${NOTE} [HyprFlux] SDDM installation options may be affected." | tee -a "$LOG"' "$INSTALL_SH"

echo "${OK} Bypassed login manager detection dialog${RESET}"

# ===========================
# 7. Replace Select Options checklist with pre-selected values
# ===========================
sed -i '/^# Initialize the options array for whiptail checklist$/,/^done$/c\
# HyprFlux: Pre-selected installation options (no whiptail dialog)\
echo "${INFO} [HyprFlux] Using pre-configured installation options..." | tee -a "$LOG"\
\
# Pre-selected options for HyprFlux\
selected_options="sddm sddm_theme gtk_themes bluetooth thunar quickshell xdph zsh dots"\
\
# Add nvidia options if detected\
if [ "$nvidia_detected" == "true" ]; then\
  selected_options="nvidia nouveau $selected_options"\
  echo "${NOTE} [HyprFlux] NVIDIA GPU detected - adding nvidia configuration" | tee -a "$LOG"\
fi\
\
# Add input_group if needed\
if [ "$input_group_detected" == "true" ]; then\
  selected_options="input_group $selected_options"\
  echo "${NOTE} [HyprFlux] Adding user to input group" | tee -a "$LOG"\
fi\
\
# Convert to array\
IFS='"'"' '"'"' read -r -a options <<< "$selected_options"\
\
# Display selected options\
echo "${OK} [HyprFlux] Selected options:" | tee -a "$LOG"\
for option in "${options[@]}"; do\
  echo "  - $option" | tee -a "$LOG"\
done\
\
echo "${OK} [HyprFlux] Proceeding with HyprFlux Hyprland Installation..." | tee -a "$LOG"' "$INSTALL_SH"

echo "${OK} Pre-selected installation options (bypassed checklist)${RESET}"

# ===========================
# 8. Remove warning dialogs inside the selection loop
# ===========================
sed -i 's/whiptail --title "Error" --msgbox "You must select at least one AUR helper to proceed\." 10 60 2/echo "${ERROR} [HyprFlux] Must select an AUR helper" | tee -a "$LOG"/' "$INSTALL_SH"
sed -i 's/whiptail --title "Error" --msgbox "You must select exactly one AUR helper\." 10 60 2/echo "${ERROR} [HyprFlux] Must select exactly one AUR helper" | tee -a "$LOG"/' "$INSTALL_SH"
sed -i 's/whiptail --title "Warning" --msgbox "No options were selected\. Please select at least one option\." 10 60/echo "${WARN} [HyprFlux] No options selected" | tee -a "$LOG"/' "$INSTALL_SH"

echo "${OK} Cleaned up remaining warning dialogs${RESET}"

# ===========================
# Summary
# ===========================
echo ""
echo "${CYAN}============================================${RESET}"
echo "${OK} HyprFlux Dialog Bypass Complete!${RESET}"
echo "${CYAN}============================================${RESET}"
echo ""
echo "${INFO} The following dialogs have been bypassed:${RESET}"
echo "  1. Welcome message dialog"
echo "  2. 'Proceed with Installation?' confirmation"
echo "  3. AUR helper selection (auto: yay)"
echo "  4. NVIDIA GPU detection notice"
echo "  5. Input group notice"
echo "  6. Login manager detection notice"
echo "  7. Options checklist (pre-selected all needed)"
echo "  8. Choices confirmation dialog"
echo ""
echo "${INFO} Pre-selected installation options:${RESET}"
echo "  [*] sddm        - SDDM login manager"
echo "  [*] sddm_theme  - SDDM theme"
echo "  [*] gtk_themes  - GTK themes"
echo "  [*] bluetooth   - Bluetooth configuration"
echo "  [*] thunar      - Thunar file manager"
echo "  [*] quickshell  - Desktop-like overview"
echo "  [*] xdph        - XDG Desktop Portal"
echo "  [*] zsh         - Zsh with Oh-My-Zsh"
echo "  [*] dots        - HyprFlux dotfiles"
echo "  [ ] rog         - ROG laptop support (disabled)"
echo "  [?] nvidia      - NVIDIA config (if detected)"
echo "  [?] input_group - Input group (if needed)"
echo ""
