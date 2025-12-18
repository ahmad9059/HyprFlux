#!/bin/bash

# ===========================
# HyprFlux Module Manager
# ===========================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared libraries
source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/config.sh"

# ===========================
# Module Discovery
# ===========================

# Get all available modules
get_available_modules() {
  find "$SCRIPT_DIR/modules" -name "*.sh" -type f | sort
}

# Get module categories
get_module_categories() {
  find "$SCRIPT_DIR/modules" -type d -mindepth 1 -maxdepth 1 | sort | xargs -I {} basename {}
}

# Get modules in category
get_modules_in_category() {
  local category="$1"
  find "$SCRIPT_DIR/modules/$category" -name "*.sh" -type f 2>/dev/null | sort
}

# ===========================
# Module Information
# ===========================

# Get module info
get_module_info() {
  local module_path="$1"
  local category=$(basename "$(dirname "$module_path")")
  local module_name=$(basename "$module_path" .sh)
  local function_name=""
  
  # Try to determine the main function name
  if grep -q "^setup_${module_name}()" "$module_path"; then
    function_name="setup_${module_name}"
  elif grep -q "^install_${module_name}()" "$module_path"; then
    function_name="install_${module_name}"
  else
    # Find the first function that looks like a main function
    function_name=$(grep -o "^[a-zA-Z_][a-zA-Z0-9_]*(" "$module_path" | head -1 | tr -d '(')
  fi
  
  echo "$category/$module_name:$function_name"
}

# ===========================
# Module Execution
# ===========================

# Load and execute a specific module
run_module() {
  local module_path="$1"
  local function_name="$2"
  
  if [[ ! -f "$module_path" ]]; then
    echo -e "${ERROR} Module not found: $module_path${RESET}"
    return 1
  fi
  
  echo -e "${ACTION} Loading module: $(basename "$module_path")${RESET}"
  source "$module_path"
  
  if declare -f "$function_name" > /dev/null; then
    echo -e "${ACTION} Executing function: $function_name${RESET}"
    if "$function_name"; then
      echo -e "${OK} Module completed successfully${RESET}"
      return 0
    else
      echo -e "${ERROR} Module execution failed${RESET}"
      return 1
    fi
  else
    echo -e "${ERROR} Function not found: $function_name${RESET}"
    echo -e "${NOTE} Available functions in module:${RESET}"
    grep -o "^[a-zA-Z_][a-zA-Z0-9_]*(" "$module_path" | tr -d '(' | sed 's/^/  - /'
    return 1
  fi
}

# ===========================
# Interactive Menu
# ===========================

# Show module menu
show_module_menu() {
  echo -e "${BLUE}================================${RESET}"
  echo -e "${BLUE} HyprFlux Module Manager${RESET}"
  echo -e "${BLUE}================================${RESET}\n"
  
  echo -e "${CYAN}Available Module Categories:${RESET}\n"
  
  local categories=($(get_module_categories))
  local i=1
  
  for category in "${categories[@]}"; do
    echo -e "  ${GREEN}$i)${RESET} $category"
    ((i++))
  done
  
  echo -e "\n  ${GREEN}0)${RESET} Exit"
  echo -e "  ${GREEN}a)${RESET} Run all modules (full setup)"
  echo -e "  ${GREEN}l)${RESET} List all modules"
  echo
}

# Show modules in category
show_category_modules() {
  local category="$1"
  local modules=($(get_modules_in_category "$category"))
  
  if [[ ${#modules[@]} -eq 0 ]]; then
    echo -e "${WARN} No modules found in category: $category${RESET}"
    return 1
  fi
  
  echo -e "${CYAN}Modules in $category:${RESET}\n"
  
  local i=1
  for module_path in "${modules[@]}"; do
    local module_name=$(basename "$module_path" .sh)
    echo -e "  ${GREEN}$i)${RESET} $module_name"
    ((i++))
  done
  
  echo -e "\n  ${GREEN}0)${RESET} Back to main menu"
  echo -e "  ${GREEN}a)${RESET} Run all modules in this category"
  echo
}

# List all modules
list_all_modules() {
  echo -e "${CYAN}All Available Modules:${RESET}\n"
  
  local categories=($(get_module_categories))
  
  for category in "${categories[@]}"; do
    echo -e "${YELLOW}$category:${RESET}"
    local modules=($(get_modules_in_category "$category"))
    
    for module_path in "${modules[@]}"; do
      local module_name=$(basename "$module_path" .sh)
      local info=$(get_module_info "$module_path")
      local function_name=$(echo "$info" | cut -d':' -f2)
      echo -e "  • $module_name ${BLUE}($function_name)${RESET}"
    done
    echo
  done
}

# ===========================
# Main Interactive Loop
# ===========================

interactive_mode() {
  while true; do
    show_module_menu
    read -rp "Select an option: " choice
    
    case "$choice" in
      0)
        echo -e "${OK} Goodbye!${RESET}"
        exit 0
        ;;
      a)
        echo -e "${ACTION} Running full setup...${RESET}"
        if [[ -f "$SCRIPT_DIR/dotsSetup_modular.sh" ]]; then
          bash "$SCRIPT_DIR/dotsSetup_modular.sh"
        else
          echo -e "${ERROR} Full setup script not found${RESET}"
        fi
        ;;
      l)
        list_all_modules
        echo
        read -rp "Press Enter to continue..."
        ;;
      [1-9]*)
        local categories=($(get_module_categories))
        local category_index=$((choice - 1))
        
        if [[ $category_index -ge 0 && $category_index -lt ${#categories[@]} ]]; then
          local selected_category="${categories[$category_index]}"
          category_menu "$selected_category"
        else
          echo -e "${ERROR} Invalid selection${RESET}"
        fi
        ;;
      *)
        echo -e "${ERROR} Invalid selection${RESET}"
        ;;
    esac
  done
}

# Category menu
category_menu() {
  local category="$1"
  
  while true; do
    echo
    show_category_modules "$category"
    read -rp "Select a module: " choice
    
    case "$choice" in
      0)
        return 0
        ;;
      a)
        echo -e "${ACTION} Running all modules in $category...${RESET}"
        run_category_modules "$category"
        ;;
      [1-9]*)
        local modules=($(get_modules_in_category "$category"))
        local module_index=$((choice - 1))
        
        if [[ $module_index -ge 0 && $module_index -lt ${#modules[@]} ]]; then
          local selected_module="${modules[$module_index]}"
          local info=$(get_module_info "$selected_module")
          local function_name=$(echo "$info" | cut -d':' -f2)
          
          echo -e "${ACTION} Running module: $(basename "$selected_module")${RESET}"
          run_module "$selected_module" "$function_name"
        else
          echo -e "${ERROR} Invalid selection${RESET}"
        fi
        ;;
      *)
        echo -e "${ERROR} Invalid selection${RESET}"
        ;;
    esac
    
    echo
    read -rp "Press Enter to continue..."
  done
}

# Run all modules in category
run_category_modules() {
  local category="$1"
  local modules=($(get_modules_in_category "$category"))
  
  for module_path in "${modules[@]}"; do
    local info=$(get_module_info "$module_path")
    local function_name=$(echo "$info" | cut -d':' -f2)
    
    echo -e "${ACTION} Running: $(basename "$module_path")${RESET}"
    if ! run_module "$module_path" "$function_name"; then
      echo -e "${WARN} Module failed, continuing with next...${RESET}"
    fi
  done
}

# ===========================
# Command Line Interface
# ===========================

# Show help
show_help() {
  echo "HyprFlux Module Manager"
  echo
  echo "Usage: $0 [options] [module]"
  echo
  echo "Options:"
  echo "  -h, --help              Show this help message"
  echo "  -l, --list              List all available modules"
  echo "  -c, --category <name>   List modules in category"
  echo "  -r, --run <module>      Run specific module"
  echo "  -i, --interactive       Interactive mode (default)"
  echo
  echo "Examples:"
  echo "  $0                      # Interactive mode"
  echo "  $0 -l                   # List all modules"
  echo "  $0 -c core              # List core modules"
  echo "  $0 -r core/packages     # Run packages module"
  echo
}

# ===========================
# Main Function
# ===========================

main() {
  # Initialize
  check_arch_linux
  start_sudo_keepalive
  
  # Setup logging
  ensure_dir "$LOG_DIR"
  exec > >(tee -a "$LOG_FILE") 2>&1
  
  case "${1:-}" in
    -h|--help)
      show_help
      ;;
    -l|--list)
      list_all_modules
      ;;
    -c|--category)
      if [[ -n "$2" ]]; then
        show_category_modules "$2"
      else
        echo -e "${ERROR} Category name required${RESET}"
        exit 1
      fi
      ;;
    -r|--run)
      if [[ -n "$2" ]]; then
        local module_spec="$2"
        local category=$(echo "$module_spec" | cut -d'/' -f1)
        local module_name=$(echo "$module_spec" | cut -d'/' -f2)
        local module_path="$SCRIPT_DIR/modules/$category/$module_name.sh"
        
        if [[ -f "$module_path" ]]; then
          local info=$(get_module_info "$module_path")
          local function_name=$(echo "$info" | cut -d':' -f2)
          run_module "$module_path" "$function_name"
        else
          echo -e "${ERROR} Module not found: $module_spec${RESET}"
          exit 1
        fi
      else
        echo -e "${ERROR} Module specification required${RESET}"
        exit 1
      fi
      ;;
    -i|--interactive|"")
      interactive_mode
      ;;
    *)
      echo -e "${ERROR} Unknown option: $1${RESET}"
      show_help
      exit 1
      ;;
  esac
  
  stop_sudo_keepalive
}

# Run main function
main "$@"