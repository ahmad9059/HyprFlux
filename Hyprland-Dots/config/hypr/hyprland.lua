-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Lua entrypoint (Hyprland >= 0.55). Replaces hyprland.conf.
--
-- Wiki: https://wiki.hypr.land/Configuring/Start/
-- Validation: Hyprland --config ~/.config/hypr/hyprland.lua --verify-config
-- Rollback: copy hypr_old/hyprland.conf over and remove this file.

local Home = os.getenv("HOME")

-- User defaults (term/files/edit/search_engine) + color palette module
local defaults = require("UserConfigs.user-defaults")
local colors = require("hyprflux-colors")

-- Settings, environment, decorations, animations
-- NOTE: hl.env calls MUST stay before any other hl.* use.
require("UserConfigs.env-variables")
require("UserConfigs.user-settings")
require("UserConfigs.user-decorations")
require("UserConfigs.user-animations")

-- Keybinds
require("configs.keybinds")
require("UserConfigs.user-keybinds")
require("UserConfigs.laptops")

-- Window/layer/workspace rules
require("UserConfigs.window-rules")
require("UserConfigs.workspace-rules") -- guide only; edit workspaces.lua (nwg-displays)

-- Autostart, monitors, workspaces
hl.on("hyprland.start", function()
    hl.exec_cmd(Home .. "/.config/hypr/initial-boot.sh")
end)
require("UserConfigs.startup-apps")
require("monitors")               -- nwg-displays generated
require("workspaces")             -- nwg-displays generated
require("UserConfigs.LaptopDisplay") -- lid-close monitor behaviour
