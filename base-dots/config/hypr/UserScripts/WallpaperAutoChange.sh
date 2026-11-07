#!/bin/bash
# Filter image files; re-detect the focused monitor on each successful change.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/../scripts/DesktopActions.py" wallpaper-auto "$@"
