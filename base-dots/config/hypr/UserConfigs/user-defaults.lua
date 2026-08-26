-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- User defaults: apps, editor, search engine (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/01-UserDefaults.conf
-- Locals are module-scoped; other files import them via require:
--   local defaults = require("UserConfigs.user-defaults")
--   hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(defaults.term))
--   hl.bind("SUPER + F",      hl.dsp.exec_cmd(defaults.files))

local defaults = {
    -- Preferred text editor. The HyprFlux Quick Settings Menu (SUPER SHIFT E)
    -- uses EDITOR and falls back to nano if unset.
    edit = os.getenv("EDITOR") or "nvim",

    -- Used by UserKeybinds.lua & Waybar modules
    term = "kitty",  -- live machine value (repo default was "foot")
    files = "thunar", -- File Manager

    -- Default Search Engine for ROFI Search (SUPER S)
    search_engine = "https://www.google.com/search?q={}",
}

return defaults
