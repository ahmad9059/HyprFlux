#!/bin/bash
# The emoji database is plain data, not executable shell source.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" rofi-emoji "$@"
