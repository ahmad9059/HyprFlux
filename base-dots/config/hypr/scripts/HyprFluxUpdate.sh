#!/bin/bash
# Read-only update check. Applying updates requires a separate reviewed action.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" check-update "$@"
