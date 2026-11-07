#!/bin/bash
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" rofi-clipboard "$@"
