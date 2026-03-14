#!/bin/bash
# HyprFlux - Replace Reads Script
# Automates user prompts in the dotfiles copy script for non-interactive installation
# 
# The Hyprland-Dots copy.sh has been refactored to use helper functions in:
# - scripts/copy_menu.sh (install/upgrade/express menu)
# - scripts/lib_prompts.sh (keyboard, resolution, clock prompts)
# - scripts/lib_apps.sh (editor choice)
#
# This script modifies these helpers to bypass interactive prompts.

set -e

# ===========================
# Color-coded status labels
# ===========================
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
OK="$(tput setaf 2)[OK]$(tput sgr0)"
NOTE="$(tput setaf 6)[NOTE]$(tput sgr0)"
ACTION="$(tput setaf 5)[ACTION]$(tput sgr0)"
RESET="$(tput sgr0)"

# ===========================
# Log Details
# ===========================
mkdir -p "$HOME/installer_log"
LOG_FILE="$HOME/installer_log/replace_reads.log"

# ===========================
# 1. Clone the Hyprland-Dots repo
# ===========================
if [ -d "$HOME/Arch-Hyprland/Hyprland-Dots" ]; then
  echo "${NOTE} Folder 'Hyprland-Dots' already exists in ~/Arch-Hyprland, using it...${RESET}"
else
  echo "${NOTE} Cloning Hyprland-Dots repo into ~/Arch-Hyprland...${RESET}"
  if git clone --depth=1 https://github.com/ahmad9059/Hyprland-Dots.git "$HOME/Arch-Hyprland/Hyprland-Dots"; then
    echo "${OK} Repo cloned successfully.${RESET}"
  else
    echo "${ERROR} Failed to clone repo. Exiting.${RESET}"
    exit 1
  fi
fi

# ===========================
# 2. Define target files
# ===========================
DOTS_DIR="$HOME/Arch-Hyprland/Hyprland-Dots"
COPY_SH="$DOTS_DIR/copy.sh"
COPY_MENU="$DOTS_DIR/scripts/copy_menu.sh"
LIB_PROMPTS="$DOTS_DIR/scripts/lib_prompts.sh"
LIB_APPS="$DOTS_DIR/scripts/lib_apps.sh"
DOTFILES_MAIN="$HOME/Arch-Hyprland/install-scripts/dotfiles-main.sh"

# Verify files exist
for f in "$COPY_SH" "$COPY_MENU" "$LIB_PROMPTS" "$LIB_APPS"; do
  if [ ! -f "$f" ]; then
    echo "${ERROR} Required file not found: $f${RESET}"
    exit 1
  fi
done

echo "${NOTE} Applying HyprFlux non-interactive modifications...${RESET}"

# ===========================
# 3. Remove git stash/pull from dotfiles-main.sh
# ===========================
if [ -f "$DOTFILES_MAIN" ]; then
  sed -i '/^[[:space:]]*git stash && git pull/d' "$DOTFILES_MAIN"
  echo "${OK} Removed git stash/pull from dotfiles-main.sh${RESET}"
fi

# ===========================
# 4. Modify copy_menu.sh - Auto-select "Install"
# ===========================
# Replace the show_copy_menu function to auto-return "install"
cat > "$COPY_MENU" << 'EOF'
#!/usr/bin/env bash
# Modified by HyprFlux for non-interactive installation

show_copy_menu() {
  # Auto-select Install for HyprFlux non-interactive mode
  COPY_MENU_CHOICE="install"
}
EOF
echo "${OK} Modified copy_menu.sh to auto-select Install${RESET}"

# ===========================
# 5. Modify lib_prompts.sh - Auto-accept defaults
# ===========================
# Backup original
cp "$LIB_PROMPTS" "$LIB_PROMPTS.bak"

# Replace keyboard layout prompt to auto-accept detected layout
sed -i '/^prompt_keyboard_layout()/,/^}/c\
prompt_keyboard_layout() {\
  local layout="$1"\
  local log="$2"\
  # HyprFlux: Auto-accept detected keyboard layout\
  if [ "$layout" = "(unset)" ]; then\
    layout="us"\
  fi\
  printf "${NOTE:-[NOTE]} Auto-configuring keyboard layout: ${MAGENTA:-}$layout${RESET:-}\\n"\
  awk -v layout="$layout" '"'"'/kb_layout/ {$0 = "  kb_layout = " layout} 1'"'"' config/hypr/configs/SystemSettings.conf >temp.conf\
  mv temp.conf config/hypr/configs/SystemSettings.conf\
  echo "${OK:-[OK]} kb_layout $layout configured in settings." 2>\&1 | tee -a "$log"\
}' "$LIB_PROMPTS"

# Replace clock format prompt to auto-select 24H (no change needed)
sed -i '/^prompt_clock_12h()/,/^}/c\
prompt_clock_12h() {\
  local log="$1"\
  # HyprFlux: Auto-select 24H format (no changes needed)\
  echo "${NOTE:-[NOTE]} Using default 24H clock format." 2>\&1 | tee -a "$log"\
}' "$LIB_PROMPTS"

# Replace express upgrade prompt to skip
sed -i '/^prompt_express_upgrade()/,/^}/c\
prompt_express_upgrade() {\
  local express_supported="$1"\
  local log="$2"\
  # HyprFlux: Skip express prompt, use standard install\
  echo "${NOTE:-[NOTE]} HyprFlux: Continuing with standard install prompts." 2>\&1 | tee -a "$log"\
}' "$LIB_PROMPTS"

echo "${OK} Modified lib_prompts.sh for non-interactive prompts${RESET}"

# ===========================
# 6. Modify lib_apps.sh - Auto-select neovim as editor
# ===========================
# Backup original
cp "$LIB_APPS" "$LIB_APPS.bak"

# Replace choose_default_editor to auto-select nvim if available
sed -i '/^choose_default_editor()/,/^}/c\
choose_default_editor() {\
  local log="$1"\
  # HyprFlux: Auto-select neovim as default editor if available\
  if command -v nvim \&>/dev/null; then\
    sed -i "s/#env = EDITOR,.*/env = EDITOR,nvim #default editor/" config/hypr/UserConfigs/01-UserDefaults.conf\
    echo "${OK:-[OK]} Default editor auto-set to ${MAGENTA:-}nvim${RESET:-}." 2>\&1 | tee -a "$log"\
  elif command -v vim \&>/dev/null; then\
    sed -i "s/#env = EDITOR,.*/env = EDITOR,vim #default editor/" config/hypr/UserConfigs/01-UserDefaults.conf\
    echo "${OK:-[OK]} Default editor auto-set to ${MAGENTA:-}vim${RESET:-}." 2>\&1 | tee -a "$log"\
  fi\
}' "$LIB_APPS"

echo "${OK} Modified lib_apps.sh to auto-select editor${RESET}"

# ===========================
# 7. Modify copy.sh - Auto-select resolution and skip prompts
# ===========================
# Replace the resolution prompt loop with auto-select >= 1440p
sed -i '/^resolution=""/,/^done$/c\
resolution="≥ 1440p"\
echo "${OK} HyprFlux: Auto-selected $resolution resolution." 2>\&1 | tee -a "$LOG"' "$COPY_SH"

# Auto-answer Ubuntu/Debian warning (skip the while loop)
sed -i '/Do you want to continue anyway/,/esac/s/read _continue/_continue="y"/' "$COPY_SH"

# Auto-answer AGS config overwrite prompt
sed -i 's/read -p "\${CAT} Do you want to overwrite your existing \${YELLOW}ags\${RESET} config? \[y\/N\] " answer_ags/answer_ags="y"/' "$COPY_SH"

# Auto-answer quickshell config overwrite prompt  
sed -i 's/read -p "\${CAT} Do you want to overwrite your existing \${YELLOW}quickshell\${RESET} config? \[y\/N\] " answer_qs/answer_qs="y"/' "$COPY_SH"

# Auto-answer SDDM wallpaper prompt
sed -i '/SDDM simple_sddm_2 theme detected/,/esac/s/read SDDM_WALL/SDDM_WALL="y"/' "$COPY_SH"

# Auto-answer additional wallpapers download (skip - too large)
sed -i '/Would you like to download additional wallpapers/,/esac/s/read WALL/WALL="n"/' "$COPY_SH"

echo "${OK} Modified copy.sh for non-interactive installation${RESET}"

# ===========================
# 8. Summary
# ===========================
echo ""
echo "${OK} ========================================${RESET}"
echo "${OK} HyprFlux non-interactive setup complete!${RESET}"
echo "${OK} ========================================${RESET}"
echo "${NOTE} The following defaults will be used:${RESET}"
echo "  - Workflow: Install (fresh copy)"
echo "  - Keyboard layout: Auto-detected (fallback: us)"
echo "  - Resolution: >= 1440p"
echo "  - Clock format: 24H"
echo "  - Default editor: nvim (if available)"
echo "  - AGS/Quickshell config: Overwrite"
echo "  - SDDM wallpaper: Apply current wallpaper"
echo "  - Additional wallpapers: Skip (1GB download)"
echo ""
