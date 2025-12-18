#!/bin/bash

set -e

# ===========================
# HyprFlux Modular Setup Script
# ===========================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared libraries
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/config.sh"

# ===========================
# Module Loading Functions
# ===========================

# Load and execute a module
load_module() {
  local module_path="$1"
  local module_name=$(basename "$module_path" .sh)
  
  if [[ -f "$module_path" ]]; then
    echo -e "${ACTION} Loading module: $module_name${RESET}"
    source "$module_path"
    return 0
  else
    echo -e "${ERROR} Module not found: $module_path${RESET}"
    return 1
  fi
}

# Execute module function safely
execute_module() {
  local function_name="$1"
  local module_name="$2"
  
  if declare -f "$function_name" > /dev/null; then
    echo -e "${ACTION} Executing: $module_name${RESET}"
    if "$function_name"; then
      echo -e "${OK} Module completed: $module_name${RESET}"
      return 0
    else
      echo -e "${ERROR} Module failed: $module_name${RESET}"
      return 1
    fi
  else
    echo -e "${ERROR} Function not found: $function_name${RESET}"
    return 1
  fi
}

# ===========================
# Main Setup Function
# ===========================

main() {
  # Check system compatibility
  check_arch_linux
  check_internet
  
  # Initialize sudo and logging
  start_sudo_keepalive
  
  # Load core modules
  load_module "$SCRIPT_DIR/modules/core/logging.sh"
  load_module "$SCRIPT_DIR/modules/core/backup.sh"
  load_module "$SCRIPT_DIR/modules/core/packages.sh"
  load_module "$SCRIPT_DIR/modules/core/dotfiles.sh"
  
  # Load application modules
  load_module "$SCRIPT_DIR/modules/apps/neovim.sh"
  load_module "$SCRIPT_DIR/modules/apps/tmux.sh"
  load_module "$SCRIPT_DIR/modules/apps/webapps.sh"
  load_module "$SCRIPT_DIR/modules/apps/shell.sh"
  
  # Load theme modules
  load_module "$SCRIPT_DIR/modules/themes/gtk.sh"
  load_module "$SCRIPT_DIR/modules/themes/icons.sh"
  load_module "$SCRIPT_DIR/modules/themes/cursors.sh"
  load_module "$SCRIPT_DIR/modules/themes/wallpapers.sh"
  
  # Load system modules
  load_module "$SCRIPT_DIR/modules/system/waybar.sh"
  load_module "$SCRIPT_DIR/modules/system/sddm.sh"
  load_module "$SCRIPT_DIR/modules/system/quickshell.sh"
  
  # Load boot modules
  load_module "$SCRIPT_DIR/modules/boot/grub.sh"
  load_module "$SCRIPT_DIR/modules/boot/plymouth.sh"
  
  # ===========================
  # Execute Setup Sequence
  # ===========================
  
  # Initialize logging
  execute_module "setup_logging" "Logging Setup" || exit 1
  
  # Core setup (required)
  execute_module "install_required_packages" "Required Packages" || exit 1
  execute_module "install_required_aur_packages" "Required AUR Packages" || exit 1
  execute_module "backup_existing_configs" "Configuration Backup" || exit 1
  execute_module "setup_dotfiles" "Dotfiles Setup" || exit 1
  
  # Application setup
  execute_module "setup_neovim" "Neovim Setup" || echo -e "${WARN} Neovim setup failed, continuing...${RESET}"
  execute_module "setup_tmux" "Tmux Setup" || echo -e "${WARN} Tmux setup failed, continuing...${RESET}"
  execute_module "setup_webapps" "Web Applications" || echo -e "${WARN} Web apps setup failed, continuing...${RESET}"
  execute_module "setup_shell_refinements" "Shell Refinements" || echo -e "${WARN} Shell refinements failed, continuing...${RESET}"
  
  # Theme setup
  execute_module "setup_gtk_themes" "GTK Themes" || echo -e "${WARN} GTK themes setup failed, continuing...${RESET}"
  execute_module "setup_icon_theme" "Icon Theme" || echo -e "${WARN} Icon theme setup failed, continuing...${RESET}"
  execute_module "setup_cursor_themes" "Cursor Themes" || echo -e "${WARN} Cursor themes setup failed, continuing...${RESET}"
  execute_module "setup_wallpapers" "Wallpapers" || echo -e "${WARN} Wallpapers setup failed, continuing...${RESET}"
  
  # System setup
  execute_module "setup_waybar" "Waybar Configuration" || echo -e "${WARN} Waybar setup failed, continuing...${RESET}"
  execute_module "setup_sddm_theme" "SDDM Theme" || echo -e "${WARN} SDDM theme setup failed, continuing...${RESET}"
  execute_module "setup_quickshell" "QuickShell Configuration" || echo -e "${WARN} QuickShell setup failed, continuing...${RESET}"
  
  # Boot setup
  execute_module "setup_grub_theme" "GRUB Theme" || echo -e "${WARN} GRUB theme setup failed, continuing...${RESET}"
  execute_module "setup_plymouth" "Plymouth Boot Screen" || echo -e "${WARN} Plymouth setup failed, continuing...${RESET}"
  
  # Optional packages (interactive)
  execute_module "install_optional_packages" "Optional Packages" || echo -e "${WARN} Optional packages setup failed, continuing...${RESET}"
  
  # Cleanup
  stop_sudo_keepalive
  
  # Final message
  echo -e "\n\n${OK} !!======= Dotfiles setup complete! =========!!${RESET}\n\n"
  log_message "INFO" "HyprFlux setup completed successfully"
}

# ===========================
# Script Entry Point
# ===========================

# Handle script arguments
case "${1:-}" in
  --help|-h)
    echo "HyprFlux Modular Setup Script"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo "  --version, -v Show version information"
    exit 0
    ;;
  --version|-v)
    echo "HyprFlux Setup Script v2.0 (Modular)"
    exit 0
    ;;
  *)
    main "$@"
    ;;
esac