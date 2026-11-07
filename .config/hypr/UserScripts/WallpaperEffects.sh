#!/bin/bash
# SUPER CTRL W: argv-based ImageMagick effects, never eval shell strings.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/../scripts/DesktopActions.py" wallpaper-effects "$@"
