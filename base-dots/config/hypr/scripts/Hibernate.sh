#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Preserve the existing entrypoint and --check option.
exec "$(dirname -- "${BASH_SOURCE[0]}")/SleepAction.sh" hibernate "$@"
