#!/bin/bash
# Station URLs remain configurable in scripts/data/radio-stations.json.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/../scripts/DesktopActions.py" rofi-music "$@"
