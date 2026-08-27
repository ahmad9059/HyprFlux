#!/bin/bash
# https://github.com/ahmad9059/HyprFlux #
# Global Functions for Scripts #

set -e

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Legacy Install-Logs dir removed — see HYPRFLUX_LOGS_DIR below.

# Show progress function
show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○" \
                      "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●") 
    local i=0

    tput civis 
    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p $pid &> /dev/null; do
        printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))  
        sleep 0.3  
    done

    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} ... Done!%-20s \n" "$package_name" ""
    tput cnorm  
}



# Function to install packages with pacman
install_package_pacman() {
  # Check if package is already installed
  if pacman -Q "$1" &>/dev/null ; then
    echo -e "${INFO} ${MAGENTA}$1${RESET} is already installed. Skipping..."
  else
    # Run pacman and redirect all output to a log file
    (
      stdbuf -oL sudo pacman -S --noconfirm "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1" 

    # Double check if package is installed
    if pacman -Q "$1" &>/dev/null ; then
      echo -e "${OK} Package ${YELLOW}$1${RESET} has been successfully installed!"
    else
      echo -e "\n${ERROR} ${YELLOW}$1${RESET} failed to install. Please check the $LOG. You may need to install manually."
    fi
  fi
}

# Unified logging: all logs under $HOME/HyprFlux/logs/installer/
HYPRFLUX_LOGS_DIR="${HYPRFLUX_LOGS_DIR:-$HOME/HyprFlux/logs}"

# Legacy "Install-Logs/" dir now points into the unified log tree.
if [ ! -d "$HYPRFLUX_LOGS_DIR/installer" ]; then
    mkdir -p "$HYPRFLUX_LOGS_DIR/installer"
fi

ISAUR=$(command -v yay || command -v paru)
# If no AUR helper exists, fall back to plain pacman (official repo packages
# still install; AUR-only packages will be reported as failed, not fatal).
if [ -z "$ISAUR" ]; then
  ISAUR="sudo pacman"
fi

# Function to install packages with either yay/paru/pacman
install_package() {
  if $ISAUR -Q "$1" &>> /dev/null ; then
    echo -e "${INFO} ${MAGENTA}$1${RESET} is already installed. Skipping..."
  else
    (
      stdbuf -oL timeout 3600 $ISAUR -S --noconfirm "$1" 2>&1
    ) >> "$LOG" 2>&1 &
    PID=$!
    show_progress $PID "$1"

    # Double check if package is installed
    if $ISAUR -Q "$1" &>> /dev/null ; then
      echo -e "${OK} Package ${YELLOW}$1${RESET} has been successfully installed!"
    else
      # Something is missing, exiting to review log
      echo -e "\n${ERROR} ${YELLOW}$1${RESET} failed to install :( , please check the install.log. You may need to install manually! Sorry I have tried :("
      echo -e "${INFO} Last 15 lines of the install log:" 
      tail -15 "$LOG" 2>/dev/null | sed 's/^/    /'
    fi
  fi
}

# Batch-install many packages in ONE transaction (official repo packages).
# Much faster than per-package yay spawns; skips already-installed.
# Usage: install_package_batch "LOG" pkg1 pkg2 ...
install_package_batch() {
  local log="$1"
  shift
  local todo=()
  local pkg
  for pkg in "$@"; do
    $ISAUR -Q "$pkg" &>> /dev/null || todo+=("$pkg")
  done
  if [ ${#todo[@]} -eq 0 ]; then
    echo -e "${OK} All packages already installed."
    return 0
  fi

  # Chunked transactions: a single failing package aborts a whole yay -S
  # transaction, so split the list (~15 per chunk) — a bad package can only
  # take down its own chunk, and the per-package fallback retries the rest.
  local chunk_size=15
  local chunk=()
  local chunk_no=0
  local any_failed=0
  local i=0

  for pkg in "${todo[@]}"; do
    chunk+=("$pkg")
    i=$((i + 1))
    if [ ${#chunk[@]} -ge $chunk_size ] || [ "$i" -eq "${#todo[@]}" ]; then
      chunk_no=$((chunk_no + 1))
      echo -e "${INFO} Installing chunk ${chunk_no} (${#chunk[@]} packages, transaction ${chunk_no}/$(( (${#todo[@]} + chunk_size - 1) / chunk_size )))..."

      (
        stdbuf -oL timeout 3600 $ISAUR -S --noconfirm --needed "${chunk[@]}" 2>&1
      ) >> "$log" 2>&1 &
      PID=$!
      show_progress $PID "packages (chunk ${chunk_no})"
      wait $PID 2>/dev/null
      local rc=$?
      if [ $rc -ne 0 ]; then
        any_failed=1
        echo -e "\n${ERROR} Chunk ${chunk_no} failed (exit ${rc}) — the per-package fallback will retry each one."
      fi
      chunk=()
    fi
  done

  # Verify the whole batch result
  local still_missing=()
  for pkg in "$@"; do
    $ISAUR -Q "$pkg" &>> /dev/null || still_missing+=("$pkg")
  done

  if [ ${#still_missing[@]} -eq 0 ]; then
    echo -e "${OK} Package batch installed successfully!"
    return 0
  fi
  echo -e "\n${ERROR} Some packages failed to install in batch: ${still_missing[*]}"
  return 1
}

# Function to just install packages with either yay or paru without checking if installed
install_package_f() {
  (
    stdbuf -oL $ISAUR -S --noconfirm "$1" 2>&1
  ) >> "$LOG" 2>&1 &
  PID=$!
  show_progress $PID "$1"  

  # Double check if package is installed
  if $ISAUR -Q "$1" &>> /dev/null ; then
    echo -e "${OK} Package ${YELLOW}$1${RESET} has been successfully installed!"
  else
    # Something is missing, exiting to review log
    echo -e "\n${ERROR} ${YELLOW}$1${RESET} failed to install :( , please check the install.log. You may need to install manually! Sorry I have tried :("
  fi
}


# Function for removing packages
uninstall_package() {
  local pkg="$1"

  # Checking if package is installed
  if pacman -Qi "$pkg" &>/dev/null; then
    echo -e "${NOTE} removing $pkg ..."
    sudo pacman -R --noconfirm "$pkg" 2>&1 | tee -a "$LOG" | grep -v "error: target not found"
    
    if ! pacman -Qi "$pkg" &>/dev/null; then
      echo -e "\e[1A\e[K${OK} $pkg removed."
    else
      echo -e "\e[1A\e[K${ERROR} $pkg Removal failed. No actions required."
      return 1
    fi
  else
    echo -e "${INFO} Package $pkg not installed, skipping."
  fi
  return 0
}