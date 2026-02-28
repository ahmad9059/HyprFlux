#!/bin/bash
# ============================================================
# lib/common.sh — Shared utilities for HyprFlux installer
# ============================================================
# Sourced by install.sh and dotsSetup.sh. Provides:
#   - Color-coded status labels (with tput fallback)
#   - Logging functions (log_info, log_ok, log_warn, log_error)
#   - setup_logging() — create log dir + exec tee
#   - setup_sudo()    — ask for sudo once, keep it alive
#   - ask_yes_no()    — reusable yes/no prompt
#   - require_cmd()   — check if commands exist
# ============================================================

# Guard against double-sourcing
[[ -n "${_LIB_COMMON_LOADED:-}" ]] && return 0
_LIB_COMMON_LOADED=1

# ====== Safe tput wrapper ======
# Returns empty string if tput fails (no terminal, missing colors, etc.)
_safe_tput() {
  tput "$@" 2>/dev/null || true
}

# ====== Color-coded status labels ======
ERROR="$(_safe_tput setaf 1)[ERROR]$(_safe_tput sgr0)"
WARN="$(_safe_tput setaf 3)[WARN]$(_safe_tput sgr0)"
OK="$(_safe_tput setaf 2)[OK]$(_safe_tput sgr0)"
NOTE="$(_safe_tput setaf 6)[NOTE]$(_safe_tput sgr0)"
ACTION="$(_safe_tput setaf 5)[ACTION]$(_safe_tput sgr0)"
INFO="$(_safe_tput setaf 4)[INFO]$(_safe_tput sgr0)"
RESET="$(_safe_tput sgr0)"

# ====== Raw colors ======
CYAN="$(_safe_tput setaf 6)"
RED="$(_safe_tput setaf 1)"
GREEN="$(_safe_tput setaf 2)"
BLUE="$(_safe_tput setaf 4)"
MAGENTA="$(_safe_tput setaf 5)"
YELLOW="$(_safe_tput setaf 3)"
SKY_BLUE="$(_safe_tput setaf 6)"
# tput setaf 214 requires 256-color support — fallback to yellow
ORANGE="$(_safe_tput setaf 214)"
[[ -z "$ORANGE" ]] && ORANGE="$YELLOW"

# ====== Logging ======
# LOG_FILE is set by setup_logging(). Until then, functions just print.
LOG_FILE="${LOG_FILE:-}"

log_info()  { echo -e "${NOTE} $*${RESET}"; }
log_ok()    { echo -e "${OK} $*${RESET}"; }
log_warn()  { echo -e "${WARN} $*${RESET}"; }
log_error() { echo -e "${ERROR} $*${RESET}"; }
log_action(){ echo -e "${ACTION} $*${RESET}"; }

# ====== setup_logging ======
# Usage: setup_logging "/path/to/logfile.log"
# Creates the log directory and redirects all stdout/stderr through tee.
# Must be called ONCE per script (not per module).
setup_logging() {
  local log_path="$1"
  local log_dir
  log_dir="$(dirname "$log_path")"

  mkdir -p "$log_dir"
  LOG_FILE="$log_path"
  exec > >(tee -a "$LOG_FILE") 2>&1
}

# ====== Sudo management ======
_SUDO_KEEP_ALIVE_PID=""

setup_sudo() {
  log_info "Asking for sudo password..."
  sudo -v

  _keep_sudo_alive() {
    while true; do
      sudo -n true 2>/dev/null
      sleep 30
    done
  }
  _keep_sudo_alive &
  _SUDO_KEEP_ALIVE_PID=$!

  # Clean up on exit, interrupt, or termination
  trap '_cleanup_sudo' EXIT INT TERM
}

_cleanup_sudo() {
  if [[ -n "$_SUDO_KEEP_ALIVE_PID" ]]; then
    kill "$_SUDO_KEEP_ALIVE_PID" 2>/dev/null || true
    _SUDO_KEEP_ALIVE_PID=""
  fi
}

# ====== Prompts ======
# Usage: ask_yes_no "Do you want to reboot?" && sudo reboot
# Returns 0 for yes, 1 for no.
ask_yes_no() {
  local prompt="${1:-Continue?}"
  local answer
  while true; do
    read -rp "$prompt [y/N]: " answer
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no|"") return 1 ;;
      *) log_error "Invalid input. Please type 'yes' or 'no'." ;;
    esac
  done
}

# ====== Dependency checking ======
# Usage: require_cmd git curl jq
# Exits with error if any command is missing.
require_cmd() {
  local missing=()
  for cmd in "$@"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required commands: ${missing[*]}"
    log_error "Please install them before continuing."
    return 1
  fi
}

# ====== Module skip mechanism ======
# Usage: should_skip "plymouth" && return 0
# Checks the SKIP_MODULES env var (comma-separated list).
should_skip() {
  local module_name="$1"
  if [[ -n "${SKIP_MODULES:-}" ]]; then
    local IFS=","
    for skip in $SKIP_MODULES; do
      # Trim whitespace
      skip="$(echo "$skip" | xargs)"
      if [[ "$skip" == "$module_name" ]]; then
        log_info "Skipping module '$module_name' (SKIP_MODULES)"
        return 0
      fi
    done
  fi
  return 1
}
