#!/usr/bin/env bash
# notes-rofi.sh — Rofi-based launcher for notes-ai (no terminal)
# Remembers last course/module selection. Pick lecture and generate.
# First entry is always "↻ Change Course/Module" to reset selection.
# Bind in hyprland.conf:
#   bind = $mainMod SHIFT, N, exec, $UserScripts/ObsidianGenerate.sh

set -euo pipefail

COURSES_ROOT="/media/Media/Courses"
NOTES_CMD="$HOME/.config/hypr/UserScripts/notes-ai"
NOTIF_ICON="$HOME/.config/swaync/images/ja.png"
LOG_FILE="/tmp/notes-ai-last.log"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/notes-ai/selection"

# ── Helpers ───────────────────────────────────────────────────────────────────
notify() {
  local title="$1"
  local message="$2"
  local urgency="${3:-normal}"
  notify-send -a "notes-ai" -i "$NOTIF_ICON" -u "$urgency" "$title" "$message"
}

die() {
  notify "Notes AI" "$1" critical
  exit 1
}

save_state() {
  mkdir -p "$(dirname "$STATE_FILE")"
  printf '%s\n%s\n' "$1" "$2" >"$STATE_FILE"
}

load_state() {
  SAVED_COURSE="" SAVED_MODULE=""
  if [[ -f "$STATE_FILE" ]]; then
    SAVED_COURSE="$(sed -n '1p' "$STATE_FILE")"
    SAVED_MODULE="$(sed -n '2p' "$STATE_FILE")"
    # Validate saved paths still exist
    if [[ ! -d "$COURSES_ROOT/$SAVED_COURSE" || ! -d "$COURSES_ROOT/$SAVED_COURSE/$SAVED_MODULE" ]]; then
      SAVED_COURSE="" SAVED_MODULE=""
      rm -f "$STATE_FILE"
    fi
  fi
}

clear_state() {
  rm -f "$STATE_FILE"
  SAVED_COURSE="" SAVED_MODULE=""
}

pick_course_module() {
  # ── Pick course ─────────────────────────────────────────────────────────
  local courses
  courses="$(find "$COURSES_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"
  [[ -n "$courses" ]] || die "No course folders found in:\n$COURSES_ROOT"

  COURSE="$(echo "$courses" | rofi -dmenu -i -p " Course" -theme-str 'window {width: 45%;}')" || exit 0

  [[ -d "$COURSES_ROOT/$COURSE" ]] || die "Course folder not found:\n$COURSE"

  # ── Pick module ─────────────────────────────────────────────────────────
  local modules
  modules="$(find "$COURSES_ROOT/$COURSE" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V)"
  [[ -n "$modules" ]] || die "No module folders found in:\n$COURSE"

  MODULE="$(echo "$modules" | rofi -dmenu -i -p " Module" -theme-str 'window {width: 50%;}')" || exit 0

  [[ -d "$COURSES_ROOT/$COURSE/$MODULE" ]] || die "Module folder not found:\n$MODULE"

  save_state "$COURSE" "$MODULE"
}

# ── Validate dependencies ────────────────────────────────────────────────────
command -v rofi >/dev/null 2>&1 || die "rofi not found in PATH"
command -v notify-send >/dev/null 2>&1 || die "notify-send not found in PATH"
[[ -x "$NOTES_CMD" ]] || die "notes-ai not found or not executable:\n$NOTES_CMD"
[[ -d "$COURSES_ROOT" ]] || die "Courses directory not found:\n$COURSES_ROOT"

# ── Load saved course/module or pick new ──────────────────────────────────────
load_state
COURSE="${SAVED_COURSE}"
MODULE="${SAVED_MODULE}"

if [[ -z "$COURSE" || -z "$MODULE" ]]; then
  pick_course_module
fi

MODULE_PATH="$COURSES_ROOT/$COURSE/$MODULE"

# ── Build subtitle file list ─────────────────────────────────────────────────
declare -A FILE_MAP
declare -a DISPLAY_ORDER=()

while IFS= read -r f; do
  base="$(basename -- "$f")"
  display="$base"
  for ext in .en_US.vtt .en.vtt .vtt .en_US.srt .en.srt .srt; do
    display="${display%"$ext"}"
  done
  FILE_MAP["$display"]="$f"
  DISPLAY_ORDER+=("$display")
done < <(find "$MODULE_PATH" -maxdepth 1 -type f \( -name '*.vtt' -o -name '*.srt' \) | sort -V)

[[ ${#FILE_MAP[@]} -gt 0 ]] || die "No .vtt or .srt files found in:\n$MODULE"

# ── Pick lecture (with reset option) ──────────────────────────────────────────
RESET_LABEL="↻ Change Course/Module"

SELECTION="$(
  {
    echo "$RESET_LABEL"
    printf '%s\n' "${DISPLAY_ORDER[@]}"
  } |
    rofi -dmenu -i -p " $COURSE / $MODULE" -theme-str 'window {width: 60%;}'
)" || exit 0

# Handle reset
if [[ "$SELECTION" == "$RESET_LABEL" ]]; then
  clear_state
  pick_course_module
  MODULE_PATH="$COURSES_ROOT/$COURSE/$MODULE"

  # Rebuild file list for new module
  FILE_MAP=()
  DISPLAY_ORDER=()
  while IFS= read -r f; do
    base="$(basename -- "$f")"
    display="$base"
    for ext in .en_US.vtt .en.vtt .vtt .en_US.srt .en.srt .srt; do
      display="${display%"$ext"}"
    done
    FILE_MAP["$display"]="$f"
    DISPLAY_ORDER+=("$display")
  done < <(find "$MODULE_PATH" -maxdepth 1 -type f \( -name '*.vtt' -o -name '*.srt' \) | sort -V)

  [[ ${#FILE_MAP[@]} -gt 0 ]] || die "No .vtt or .srt files found in:\n$MODULE"

  SELECTION="$(
    printf '%s\n' "${DISPLAY_ORDER[@]}" |
      rofi -dmenu -i -p " $COURSE / $MODULE" -theme-str 'window {width: 60%;}'
  )" || exit 0
fi

SUB_FILE="${FILE_MAP[$SELECTION]:-}"
[[ -n "$SUB_FILE" && -f "$SUB_FILE" ]] || die "Selected file not found:\n$SELECTION"

# ── Generate notes in background ──────────────────────────────────────────────
notify "Generating Notes" "$SELECTION\n$COURSE → $MODULE" normal

nohup bash -c '
  NOTES_CMD="$1"
  SUB_FILE="$2"
  SELECTION="$3"
  COURSE="$4"
  MODULE="$5"
  NOTIF_ICON="$6"
  LOG_FILE="$7"

  ntfy() {
    notify-send -a "notes-ai" -i "$NOTIF_ICON" -u "$3" "$1" "$2"
  }

  if yes y | "$NOTES_CMD" "$SUB_FILE" > "$LOG_FILE" 2>&1; then
    ntfy "Notes Ready" "$SELECTION\n$COURSE → $MODULE" normal
  else
    EXIT_CODE=$?
    LAST_LINES="$(tail -3 "$LOG_FILE" 2>/dev/null || echo "No log output")"
    ntfy "Generation Failed" "$SELECTION\nExit: $EXIT_CODE\n$LAST_LINES" critical
  fi
' _ "$NOTES_CMD" "$SUB_FILE" "$SELECTION" "$COURSE" "$MODULE" "$NOTIF_ICON" "$LOG_FILE" \
  >/dev/null 2>&1 &

disown
