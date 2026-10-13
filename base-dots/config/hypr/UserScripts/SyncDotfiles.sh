#!/bin/bash
set -e

# Paths
REPO_DIR="$HOME/HyprFlux"
NOTIF_ICON="dialog-information"
INITIAL_BOOT_FILE="$REPO_DIR/.config/hypr/.initial_startup_done"

# Send notification
notify() {
  local title="$1"
  local message="$2"
  local urgency="$3" # low, normal, critical
  notify-send -i "$NOTIF_ICON" -u "$urgency" "$title" "$message"
}

# Error handler
on_error() {
  local exit_code=$?
  notify "HyprFlux Sync Failed" "Script exited with code $exit_code" critical
  exit $exit_code
}
trap on_error ERR

# Sync .config items that exist in repo
notify-send -a "HyprFlux Sync" -i dialog-information "HyprFlux Sync" "Sync has been started..."
echo -e "Syncing from system to repo (for changes you made locally)..."
for item in "$REPO_DIR/.config"/*; do
  name=$(basename "$item")
  if [ -d "$HOME/.config/$name" ]; then
    rsync -av --delete "$HOME/.config/$name/" "$REPO_DIR/.config/$name/"
  elif [ -f "$HOME/.config/$name" ]; then
    cp "$HOME/.config/$name" "$REPO_DIR/.config/$name"
  fi
done

# Sync top-level items (excluding .icons)
rsync -av --delete "$HOME/.themes/" "$REPO_DIR/.themes/"

# Only sync tmuxifier layouts folder
mkdir -p "$REPO_DIR/.tmuxifier/layouts"
rsync -av --delete "$HOME/.tmuxifier/layouts/" "$REPO_DIR/.tmuxifier/layouts/"

# Other top-level configs
[ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$REPO_DIR/.zshrc"
[ -f "$HOME/.tmux.conf" ] && cp "$HOME/.tmux.conf" "$REPO_DIR/.tmux.conf"

echo -e "Local changes synced to repo..."

# === Apply custom modifications before commit/push ===

# 1. Break the Waybar symlinks so they can be recreated later
WAYBAR_CONFIG="$REPO_DIR/.config/waybar/config"
WAYBAR_STYLE="$REPO_DIR/.config/waybar/style.css"
if [ -L "$WAYBAR_CONFIG" ]; then
  rm "$WAYBAR_CONFIG"
fi
if [ -L "$WAYBAR_STYLE" ]; then
  rm "$WAYBAR_STYLE"
fi

# Remove Hyprland initial startup marker file (if present)
if [ -f "$INITIAL_BOOT_FILE" ]; then
  rm -f "$INITIAL_BOOT_FILE"
  echo -e "Removed initial startup marker...}"
fi

# Commit and push changes to personal branch
PERSONAL_BRANCH="personal"

echo -e "Committing and pushing changes to branch '$PERSONAL_BRANCH'..."
cd "$REPO_DIR"

# Make sure the branch exists and switch to it
if git rev-parse --verify "$PERSONAL_BRANCH" >/dev/null 2>&1; then
  git checkout "$PERSONAL_BRANCH"
else
  git checkout -b "$PERSONAL_BRANCH"
fi

git add .
if git commit -m "Sync local changes $(date '+%Y-%m-%d %H:%M:%S')" && sleep 3; then
  git push -u origin "$PERSONAL_BRANCH"
  sleep 3
  notify "HyprFlux Sync Completed" "Changes committed and pushed successfully to $PERSONAL_BRANCH" normal
else
  sleep 3
  notify "HyprFlux Sync" "Already synced to newest changes on $PERSONAL_BRANCH" low
fi
