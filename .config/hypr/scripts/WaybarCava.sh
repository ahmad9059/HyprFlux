#!/bin/bash
# Optional visualizer: each bar owns its Cava process and private configuration.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/WaybarStatus.py" cava "$@"
