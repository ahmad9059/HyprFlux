#!/bin/bash
set -Eeuo pipefail

# Notification icon
NOTIF_ICON="dialog-information"

# Error handler
on_error() {
  local exit_code=$?
  local last_command=${BASH_COMMAND}
  notify-send -u critical -i "$NOTIF_ICON" "Blog Sync Failed" "Command \`$last_command\` failed with exit code $exit_code."
  exit $exit_code
}
trap on_error ERR

# Define paths
sourcePath="/home/ahmad/Documents/obsidian/posts/"
destinationPath="/home/ahmad/Documents/blog/content/posts/"
repoPath="/home/ahmad/Documents/blog"

notify-send -a "Blog Sync Started" -i dialog-information "Blog Sync Started" "Syncing the blog started..."

# Check for required commands
for cmd in git rsync python3 hugo; do
  if ! command -v "$cmd" &>/dev/null; then
    notify-send -u critical -i "$NOTIF_ICON" "Missing Command" "$cmd is not installed or not in PATH."
    exit 1
  fi
done

# Ensure paths exist
if [ ! -d "$sourcePath" ]; then
  notify-send -u critical -i "$NOTIF_ICON" "Source Path Missing" "$sourcePath does not exist."
  exit 1
fi

if [ ! -d "$destinationPath" ]; then
  notify-send -u critical -i "$NOTIF_ICON" "Destination Path Missing" "$destinationPath does not exist."
  exit 1
fi

# Rsync sync
echo "Syncing posts from Obsidian..."
if ! rsync -av --delete "$sourcePath" "$destinationPath"; then
  notify-send -u critical -i "$NOTIF_ICON" "Rsync Failed" "Failed to sync posts to Hugo."
  exit 1
fi

# Git stage, commit and push (inside blog repo)
cd "$repoPath"

echo "Staging changes..."
git add .

commit_message="New Blog Post on $(date +'%Y-%m-%d %H:%M:%S')"
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  echo "Committing changes..."
  git commit -m "$commit_message"
fi

echo "Pushing to GitHub..."
if ! git push origin main && sleep 3; then
  notify-send -u critical -i "$NOTIF_ICON" "Git Push Failed" "Failed to push to main branch."
  exit 1
fi

# ✅ Success notification
notify-send -u low -i "$NOTIF_ICON" "Blog Sync Completed" "Your blog has been synced and pushed to GitHub."
