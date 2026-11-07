#!/bin/bash
# A uniquely identified dropdown; never guess another application's address.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/DesktopActions.py" dropdown "$@"
