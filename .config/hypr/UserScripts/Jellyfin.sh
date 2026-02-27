#!/bin/bash

SERVICE_NAME="jellyfin"

notify() {
  local message="$1"
  local urgency="${2:-normal}"
  local icon="${3:-dialog-information}"
  notify-send -u "$urgency" -i "$icon" "Jellyfin Service" "$message"
}

# Check if the service is active
if systemctl is-active --quiet "$SERVICE_NAME"; then
  notify "Jellyfin is running. Stopping service..." "low" "dialog-warning"
  if systemctl stop "$SERVICE_NAME"; then
    sleep 1
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
      notify "Jellyfin stopped successfully." "normal" "dialog-information"
    else
      notify "Failed to stop Jellyfin." "critical" "dialog-error"
      exit 1
    fi
  else
    notify "Permission denied to stop Jellyfin." "critical" "dialog-error"
    exit 1
  fi
else
  notify "Jellyfin is not running. Starting service..." "low" "dialog-warning"
  if systemctl start "$SERVICE_NAME"; then
    sleep 1
    if systemctl is-active --quiet "$SERVICE_NAME"; then
      notify "Jellyfin started successfully." "normal" "dialog-information"
    else
      notify "Failed to start Jellyfin." "critical" "dialog-error"
      exit 1
    fi
  else
    notify "Permission denied to start Jellyfin." "critical" "dialog-error"
    exit 1
  fi
fi
