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

# The repo may live anywhere (default $HOME/HyprFlux, but ISO clones it under
# the target user's home too). Pin HYPRFLUX_DIR to this clone unless the user
# explicitly overrode it — otherwise dotsSetup/base-installer would resolve
# paths against $HOME/HyprFlux and break on custom checkout locations.
HYPRFLUX_DIR="${HYPRFLUX_DIR:-$SCRIPT_DIR}"

# ====== Source shared libraries ======
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/git.sh"

# ====== Logging ======
setup_logging "$HYPRFLUX_LOGS_DIR/install.log"

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
# Fresh Arch installs often have a stale/empty keyring that makes the very
# first `pacman -Syu` fail with "GPG keys are outdated". Initialize/populate
# it first (safe even if already present), then sync.
log_info "Ensuring pacman keyring is initialized..."
if ! sudo pacman-key --init 2>/dev/null; then
  log_warn "pacman-key --init failed (non-fatal, continuing)."
fi
if ! sudo pacman-key --populate archlinux 2>/dev/null; then
  log_warn "pacman-key --populate failed (non-fatal, continuing)."
fi

log_info "Updating system and ensuring git & vim are installed..."
if ! sudo pacman -Syu --noconfirm git vim; then
  # Retry once after refreshing the keyring (common on stale installs)
  log_warn "First sync failed — refreshing keyring and retrying..."
  sudo pacman-key --refresh-keys 2>/dev/null || true
  sudo pacman -Syu --noconfirm git vim
fi
log_ok "System updated, git & vim are ready."

# ====== Step 1: Run merged base-installer ======
# base-installer (was Arch-Hyprland) is merged into this repo — no clone needed.
# Its install.sh is already pre-patched for fully automated installation
# (whiptail dialogs bypassed, options pre-selected). base-dots is also
# merged and pre-patched; dotfiles-main.sh points to it.
ARCH_HYPRLAND_DIR="$HYPRFLUX_DIR/base-installer"

if [[ ! -f "$ARCH_HYPRLAND_DIR/install.sh" ]]; then
  log_error "Merged base-installer not found at $ARCH_HYPRLAND_DIR/install.sh"
  exit 1
fi

log_info "Running base-installer/install.sh (merged, fully automated)..."
chmod +x "$ARCH_HYPRLAND_DIR/install.sh"
# IMPORTANT: Must cd into the directory because base-installer's install.sh
# uses relative paths (e.g., install-scripts/) that only resolve from there.
(cd "$ARCH_HYPRLAND_DIR" && bash install.sh)
log_ok "base-installer script completed!"

# ====== Step 2: HyprFlux banner ======
clear
echo -e "\n"
echo -e "${MAGENTA}┌┬┐┌─┐┌┬┐┌─┐┬┬  ┌─┐┌─┐┌─┐  ┬┌┐┌┌─┐┌┬┐┌─┐┬  ┬  ┌─┐┬─┐${RESET}"
echo -e "${MAGENTA} │││ │ │ ├┤ ││  ├┤ └─┐└─┐  ││││└─┐ │ ├─┤│  │  ├┤ ├┬┘${RESET}"
echo -e "${MAGENTA}─┴┘└─┘ ┴ └  ┴┴─┘└─┘└─┘└─┘  ┴┘└┘└─┘ ┴ ┴ ┴┴─┘┴─┘└─┘┴└─${RESET}"
echo -e "${CYAN}✻─────────────────────ahmad9059──────────────────────✻${RESET}"
echo -e "\n"

# ====== Step 3: Run HyprFlux dotsSetup ======
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
