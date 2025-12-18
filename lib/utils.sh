#!/bin/bash

# Source colors
source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# ================================
# Utility Functions
# ================================

# Keep sudo alive
keep_sudo_alive() {
  while true; do
    sudo -n true
    sleep 30
  done
}

# Start sudo keep alive process
start_sudo_keepalive() {
  echo "${NOTE} Asking for sudo password...${RESET}"
  sudo -v
  keep_sudo_alive &
  export SUDO_KEEP_ALIVE_PID=$!
  trap 'kill $SUDO_KEEP_ALIVE_PID 2>/dev/null' EXIT
}

# Stop sudo keep alive process
stop_sudo_keepalive() {
  if [[ -n "$SUDO_KEEP_ALIVE_PID" ]]; then
    kill $SUDO_KEEP_ALIVE_PID 2>/dev/null
  fi
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if package is installed
package_installed() {
  pacman -Qi "$1" &>/dev/null
}

# Retry function with exponential backoff
retry_with_backoff() {
  local max_attempts="$1"
  local delay="$2"
  local command="$3"
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    if eval "$command"; then
      return 0
    fi
    
    if [ $attempt -eq $max_attempts ]; then
      echo -e "${ERROR} Command failed after $max_attempts attempts: $command${RESET}"
      return 1
    fi
    
    echo -e "${WARN} Attempt $attempt failed. Retrying in ${delay}s...${RESET}"
    sleep $delay
    delay=$((delay * 2))  # Exponential backoff
    attempt=$((attempt + 1))
  done
}

# Create directory if it doesn't exist
ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    echo -e "${OK} Created directory: $dir${RESET}"
  fi
}

# Backup file or directory
backup_item() {
  local source="$1"
  local backup_dir="$2"
  local item_name=$(basename "$source")
  
  if [[ -e "$source" ]]; then
    ensure_dir "$backup_dir"
    cp -r "$source" "$backup_dir/"
    echo -e "${OK} Backed up: $item_name${RESET}"
  fi
}

# Check if running on Arch Linux
check_arch_linux() {
  if [[ ! -f /etc/arch-release ]]; then
    echo -e "${ERROR} This script is designed for Arch Linux only.${RESET}"
    exit 1
  fi
}

# Print section header
print_section() {
  local title="$1"
  echo -e "\n${BLUE}================================${RESET}"
  echo -e "${BLUE} $title${RESET}"
  echo -e "${BLUE}================================${RESET}\n"
}

# Print package list
print_package_list() {
  local title="$1"
  shift
  local packages=("$@")
  
  echo -e "\n\033[1;34m$title:\033[0m\n"
  for pkg in "${packages[@]}"; do
    echo -e "  • $pkg"
  done
  echo
}

# Ask yes/no question
ask_yes_no() {
  local question="$1"
  local default="${2:-no}"
  
  while true; do
    if [[ "$default" == "yes" ]]; then
      read -rp "$question [Y/n]: " answer
      answer=${answer:-y}
    else
      read -rp "$question [y/N]: " answer
      answer=${answer:-n}
    fi
    
    case "${answer,,}" in
      yes|y) return 0 ;;
      no|n) return 1 ;;
      *) echo -e "${ERROR} Please answer 'yes' or 'no'.${RESET}" ;;
    esac
  done
}

# Log message to file and stdout
log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Check internet connectivity
check_internet() {
  if ! ping -c 1 google.com &>/dev/null; then
    echo -e "${ERROR} No internet connection. Please check your network.${RESET}"
    exit 1
  fi
}

# Get script directory
get_script_dir() {
  echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

# Source module safely
source_module() {
  local module_path="$1"
  if [[ -f "$module_path" ]]; then
    source "$module_path"
  else
    echo -e "${ERROR} Module not found: $module_path${RESET}"
    exit 1
  fi
}