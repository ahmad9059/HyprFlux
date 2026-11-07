#!/bin/bash
# Use awww's public query API, not its private cache layout.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" wallpaper-sync "$@"
