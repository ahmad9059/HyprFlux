#!/bin/bash
# ============================================================
# install.sh — HyprFlux top-level entry point
# ============================================================
# Supports two modes:
#   1. Piped from curl: sh <(curl -fsSL https://hyprflux.dev/install)
#      → Bootstraps git, clones the repo, re-execs from the clone.
#   2. Run locally: bash ~/HyprFlux/install.sh
#      → Sources libs and runs directly.
# ============================================================

set -e

# ====== Configurable URLs (available in both bootstrap & main) ======
HYPRFLUX_REPO="${HYPRFLUX_REPO:-https://github.com/ahmad9059/HyprFlux.git}"
HYPRFLUX_DIR="${HYPRFLUX_DIR:-$HOME/HyprFlux}"

# ============================================================
# Bootstrap: detect curl-pipe mode and re-exec from local clone
# ============================================================
# When run via sh <(curl ...), BASH_SOURCE[0] is something like
# /dev/fd/63 — there's no real directory to resolve lib/ from.
# Fix: clone the repo first, then exec the real install.sh.
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd 2>/dev/null || echo "")"
if [[ -z "$_script_dir" ]] || [[ "$_script_dir" == "/dev/fd" ]] || [[ "$_script_dir" == "/dev" ]] || [[ ! -f "$_script_dir/lib/common.sh" ]]; then
  echo ""
  echo "  Bootstrapping HyprFlux (running from curl pipe)..."
  echo ""

  # Ensure git is available
  if ! command -v git &>/dev/null; then
    echo "  Installing git..."
    sudo pacman -Sy --noconfirm git
  fi

  # Clone or update the repo
  if [[ -d "$HYPRFLUX_DIR/.git" ]]; then
    echo "  HyprFlux repo found at $HYPRFLUX_DIR, pulling latest..."
    git -C "$HYPRFLUX_DIR" pull --ff-only 2>/dev/null || true
  else
    echo "  Cloning HyprFlux to $HYPRFLUX_DIR..."
    git clone --depth=1 "$HYPRFLUX_REPO" "$HYPRFLUX_DIR"
  fi

  # Re-exec the real install.sh from the cloned repo
  echo "  Launching installer from $HYPRFLUX_DIR/install.sh..."
  echo ""
  exec bash "$HYPRFLUX_DIR/install.sh"
fi
# ============================================================
# If we reach here, we're running from a real directory with libs
# ============================================================

SCRIPT_DIR="$_script_dir"
unset _script_dir

# ====== Source shared libraries ======
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/git.sh"

# ====== Logging ======
setup_logging "$HOME/hyprflux_log/install.log"

# ====== Banner ======
clear
echo -e "\n"
echo -e "${CYAN}     ██╗  ██╗██╗   ██╗██████╗ ██████╗ ███████╗██╗     ██╗   ██╗██╗  ██╗${RESET}"
echo -e "${CYAN}     ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║     ██║   ██║╚██╗██╔╝${RESET}"
echo -e "${CYAN}     ███████║ ╚████╔╝ ██████╔╝██████╔╝█████╗  ██║     ██║   ██║ ╚███╔╝ ${RESET}"
echo -e "${CYAN}     ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██╔══╝  ██║     ██║   ██║ ██╔██╗ ${RESET}"
echo -e "${CYAN}     ██║  ██║   ██║   ██║     ██║  ██║██║     ███████╗╚██████╔╝██╔╝ ██╗${RESET}"
echo -e "${CYAN}     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝${RESET}"
echo -e "${RED}     ✻────────────────────────────ahmad9059────────────────────────────✻${RESET}"
echo -e "${GREEN}           Welcome to HyprFlux! lets begin Installation${RESET}"
echo -e "\n"

# ====== Sudo ======
setup_sudo

# ====== System update & prerequisites ======
log_info "Updating system and ensuring git & vim are installed..."
sudo pacman -Syu --noconfirm git vim
log_ok "System updated, git & vim are ready."

# ====== Configurable URLs ======
ARCH_HYPRLAND_REPO="${ARCH_HYPRLAND_REPO:-https://github.com/ahmad9059/Arch-Hyprland.git}"
ARCH_HYPRLAND_DIR="${ARCH_HYPRLAND_DIR:-$HOME/Arch-Hyprland}"

# ====== Step 1: Clone & run Arch-Hyprland ======
ensure_repo "$ARCH_HYPRLAND_REPO" "$ARCH_HYPRLAND_DIR" --depth=1

log_info "Running Arch-Hyprland/install.sh with preset answers..."
sed -i '/^[[:space:]]*read HYP$/c\HYP="n"' "$ARCH_HYPRLAND_DIR/install.sh"
chmod +x "$ARCH_HYPRLAND_DIR/install.sh"
# IMPORTANT: Must cd into the directory because Arch-Hyprland's install.sh
# uses relative paths (e.g., install-scripts/) that only resolve from there.
(cd "$ARCH_HYPRLAND_DIR" && bash install.sh)
log_ok "Arch-Hyprland script installed!"

# ====== Step 2: HyprFlux banner ======
clear
echo -e "\n"
echo -e "${MAGENTA}┌┬┐┌─┐┌┬┐┌─┐┬┬  ┌─┐┌─┐┌─┐  ┬┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐${RESET}"
echo -e "${MAGENTA} │││ │ │ ├┤ ││  ├┤ └─┐└─┐  ││││└─┐ │ ├─┤│  │  ├┤ ├┬┘${RESET}"
echo -e "${MAGENTA}─┴┘└─┘ ┴ └  ┴┴─┘└─┘└─┘└─┘  ┴┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─${RESET}"
echo -e "${CYAN}✻─────────────────────ahmad9059──────────────────────✻${RESET}"
echo -e "\n"

# ====== Step 3: Clone & run HyprFlux dotsSetup ======
ensure_repo "$HYPRFLUX_REPO" "$HYPRFLUX_DIR" --depth=1

log_info "Running HyprFlux dotsSetup.sh..."
chmod +x "$HYPRFLUX_DIR/dotsSetup.sh"
bash "$HYPRFLUX_DIR/dotsSetup.sh"

# ====== Step 4: Reboot prompt ======
# When HYPRFLUX_ISO_MODE=1, the ISO installer handles reboot — skip the prompt
if [[ -z "${HYPRFLUX_ISO_MODE:-}" ]]; then
  if ask_yes_no "Do you want to reboot now?"; then
    log_ok "Rebooting..."
    sudo reboot
  else
    log_ok "You chose NOT to reboot. Please reboot later."
  fi
else
  log_ok "HyprFlux setup complete (ISO mode — reboot handled by installer)."
fi
