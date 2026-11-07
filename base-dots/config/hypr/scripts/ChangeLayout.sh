#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Cycle only the visible workspace; respect workspace-specific layout rules.
set -euo pipefail

hyprctl eval '
local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
if not workspace then return end
local layouts = { dwindle = "master", master = "scrolling", scrolling = "dwindle" }
local next_layout = layouts[workspace.tiled_layout] or "dwindle"
local selector = workspace.special and workspace.name or ("name:" .. workspace.name)
hl.workspace_rule({ workspace = selector, layout = next_layout })
hl.exec_cmd("notify-send -e -u low -i dialog-information \"Workspace layout\" " .. next_layout)
'
