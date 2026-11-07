#!/bin/bash
# Lua profiles only; do not report obsolete .conf files as successfully applied.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" monitor-preset "$@"
