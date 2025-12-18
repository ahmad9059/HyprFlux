#!/bin/bash

# ===========================
# Color-coded status labels
# ===========================
export ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
export WARN="$(tput setaf 3)[WARN]$(tput sgr0)"
export OK="$(tput setaf 2)[OK]$(tput sgr0)"
export NOTE="$(tput setaf 6)[NOTE]$(tput sgr0)"
export ACTION="$(tput setaf 4)[ACTION]$(tput sgr0)"
export INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
export CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"

# ===========================
# Color codes
# ===========================
export MAGENTA="$(tput setaf 5)"
export ORANGE="$(tput setaf 214)"
export WARNING="$(tput setaf 1)"
export YELLOW="$(tput setaf 3)"
export GREEN="$(tput setaf 2)"
export BLUE="$(tput setaf 4)"
export SKY_BLUE="$(tput setaf 6)"
export CYAN="$(tput setaf 6)"
export RED="$(tput setaf 1)"
export RESET="$(tput sgr0)"