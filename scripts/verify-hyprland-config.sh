#!/bin/bash
# Parse config without a compositor/session, never with root compositor privileges.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
config="${1:-$root/.config/hypr/hyprland.lua}"
[[ -r "$config" ]] || { echo "Config is not readable: $config" >&2; exit 1; }
# Keep runtime socket paths short. All state belongs to this isolated check.
runtime=$(mktemp -d /tmp/hv.XXXXXX)
home=$(mktemp -d /tmp/hhome.XXXXXX)
trap 'rm -rf -- "$runtime" "$home"' EXIT
if (( EUID == 0 )); then
    # Root --i-am-really-stupid verification can crash on a fresh IPC socket in
    # Hyprland 0.57.1. Validate as an actual unprivileged desktop user instead.
    chown "nobody:$(id -gn nobody)" "$runtime" "$home"
    runuser -u nobody -- env HOME="$home" XDG_RUNTIME_DIR="$runtime" \
        Hyprland --config "$config" --verify-config
else
    HOME="$home" XDG_RUNTIME_DIR="$runtime" Hyprland --config "$config" --verify-config
fi
