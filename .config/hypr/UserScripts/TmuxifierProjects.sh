#!/bin/bash
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/../scripts/DesktopActions.py" rofi-projects "$@"
