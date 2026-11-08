#!/bin/bash
# Read app defaults without evaluating Lua or interpolating shell commands.
exec python3 "$(dirname -- "${BASH_SOURCE[0]}")/WaybarStatus.py" launch "$@"
