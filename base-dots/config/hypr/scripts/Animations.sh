#!/bin/bash
# Select, validate and apply a Lua preset; restore the old file on reload error.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" animation-preset "$@"
