#!/bin/bash
# Explicit recovery only. Let D-Bus/systemd own portal lifetime and executable paths.
set -euo pipefail
if [[ "${1:-}" != --restart ]]; then
    echo 'Portal recovery interrupts active screen-sharing. Run PortalHyprland.sh --restart explicitly.' >&2
    exit 2
fi
systemctl --user restart xdg-desktop-portal-hyprland.service
systemctl --user restart xdg-desktop-portal.service
