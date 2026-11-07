#!/bin/bash
# Typed, session-local state; no wallpaper or unrelated process changes.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" game-mode "$@"
