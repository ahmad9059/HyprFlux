#!/usr/bin/env bash
set -euo pipefail

DOCS="$HOME/Documents/Projects/"
TMUXIFIER_BIN="$HOME/.tmuxifier/bin/tmuxifier"

project="$(find "$DOCS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort \
  | rofi -dmenu -i -p "Project")"

[ -z "${project:-}" ] && exit 0

PROJECT_DIR="$DOCS/$project"
SESSION_NAME="$project"

exec kitty --title "tmuxifier: $project" -e zsh -lc "
  export PROJECT_DIR=\"$PROJECT_DIR\"
  export SESSION_NAME=\"$SESSION_NAME\"
  \"$TMUXIFIER_BIN\" load-session web-dev
"
