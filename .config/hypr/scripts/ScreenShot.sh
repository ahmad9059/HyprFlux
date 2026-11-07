#!/bin/bash
# Cancellation-safe capture, atomic saves and meaningful failure status.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" screenshot "$@"
