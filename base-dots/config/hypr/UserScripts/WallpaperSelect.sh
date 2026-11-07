#!/bin/bash
# Index-based selection preserves spaces, extensions and duplicate basenames.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/../scripts/DesktopActions.py" wallpaper-select "$@"
