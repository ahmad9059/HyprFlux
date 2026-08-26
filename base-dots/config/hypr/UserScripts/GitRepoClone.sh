#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# GitHub repo cloner — list your repos in rofi, pick one, clone it.
# Already-cloned repos are marked ✓ and reported instead of re-cloning.
# Uses `gh` (GitHub CLI) — requires `gh auth login` once.

CLONE_DIR="$HOME/Documents/Projects"
GITHUB_USER=""   # auto-detected from gh if empty

notif_icon="folder"
notif_err="dialog-error"

# resolve the GitHub username (gh api user -> login)
if [[ -z "$GITHUB_USER" ]]; then
    GITHUB_USER=$(gh api user -q .login 2>/dev/null)
fi
if [[ -z "$GITHUB_USER" ]]; then
    notify-send -i "$notif_err" "GitHub Clone" "Could not determine your GitHub username — run \`gh auth login\` first"
    exit 1
fi

mkdir -p "$CLONE_DIR"

# fetch the repo list (name only)
repos=$(gh repo list "$GITHUB_USER" --json nameWithOwner -L 300 2>/dev/null | jq -r '.[].nameWithOwner')
if [[ -z "$repos" ]]; then
    notify-send -i "$notif_err" "GitHub Clone" "Could not fetch repositories (check network / gh auth)"
    exit 1
fi

# mark repos that are already cloned
menu=$(echo "$repos" | while IFS= read -r full; do
    name="${full#*/}"
    if [[ -d "$CLONE_DIR/$name" ]]; then
        printf "✓ %s\n" "$full"
    else
        printf "%s\n" "$full"
    fi
done)

choice=$(echo "$menu" | rofi -dmenu -i -p "Clone GitHub repo" -mesg "✓ = already cloned  •  target: $CLONE_DIR")
[[ -z "$choice" ]] && exit 0

full="${choice#✓ }"
name="${full#*/}"
target="$CLONE_DIR/$name"

if [[ -d "$target" ]]; then
    notify-send -i "$notif_icon" "Already cloned" "$full exists at $target"
    exit 0
fi

notify-send -i "$notif_icon" "Cloning started" "$full → $target"

if err=$(git clone "https://github.com/$full.git" "$target" 2>&1); then
    notify-send -i "$notif_icon" "Cloned" "$full → $target"
else
    reason=$(echo "$err" | grep -iE 'error|fatal|not found|denied' | head -1)
    reason=${reason:-"unknown error"}
    notify-send -u critical -i "$notif_err" "Clone failed" "$full: $reason"
fi
