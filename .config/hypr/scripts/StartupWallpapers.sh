#!/bin/bash
# Single owner for image/video wallpaper startup and saved selection restoration.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" wallpaper-restore "$@"
