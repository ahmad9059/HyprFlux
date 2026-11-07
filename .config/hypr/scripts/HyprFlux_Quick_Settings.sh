#!/bin/bash
# Every visible option has a handler; unavailable optional browsers are hidden.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" quick-settings "$@"
