-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Lua entrypoint (Hyprland >= 0.55). Replaces hyprland.conf
--
-- PHASE 1 STATUS: skeleton only — NOT YET ACTIVE as the boot entrypoint.
-- The live session still boots hyprland.conf until the final flip (Phase 6).
-- Validation: Hyprland --config <this file> --verify-config
--
-- Always refer to the Hyprland wiki: https://wiki.hypr.land/Configuring/Start/

local Home = os.getenv("HOME")

-- ===== Phase 1: skeleton (proves require chain + module patterns) =====
local defaults = require("UserConfigs.user-defaults") -- term/files/edit/search_engine
local colors = require("hyprflux-colors")             -- palette table (used from Phase 2 on)

-- ===== Phase 2 (settings/colors/env) — ACTIVE =====
-- hl.env calls MUST stay before any other hl.* use:
require("UserConfigs.env-variables")
require("UserConfigs.user-settings")
require("UserConfigs.user-decorations")
require("UserConfigs.user-animations")

-- ===== Phase 3 (keybinds) — ACTIVE =====
require("configs.keybinds")
require("UserConfigs.user-keybinds")
require("UserConfigs.laptops")

-- ===== Phase 4 (window/layer/workspace rules) — ACTIVE =====
require("UserConfigs.window-rules")
require("UserConfigs.workspace-rules") -- guide only; edit workspaces.lua (nwg-displays)

-- ===== Phase 5 (autostart, monitors, workspaces) — ACTIVE =====
hl.on("hyprland.start", function()
    hl.exec_cmd(Home .. "/.config/hypr/initial-boot.sh")
end)
require("UserConfigs.startup-apps")
require("monitors")   -- nwg-displays generated
require("workspaces") -- nwg-displays generated
require("UserConfigs.LaptopDisplay") -- lid-close monitor behaviour

-- ===== Phase 6: flip =====
-- Delete hyprland.conf from the tree; ship this file as the only entrypoint.
