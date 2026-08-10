-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- User keybinds (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/UserKeybinds.conf (46 binds)
-- Be mindful to check configs/keybinds.lua to avoid conflicts.
-- If you think a pre-defined keybind in configs/keybinds.lua should change,
-- submit an issue / open a discussion with a valid reason (e.g. conflict
-- with global shortcuts).

local defaults = require("UserConfigs.user-defaults")

local Home = os.getenv("HOME")
local mainMod = "SUPER"
local scriptsDir = Home .. "/.config/hypr/scripts"
local UserScripts = Home .. "/.config/hypr/UserScripts"
local UserConfigs = Home .. "/.config/hypr/UserConfigs"

-- common shortcuts
-- hl.bind(mainMod .. " + " .. mainMod .. "_L", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -modi drun,filebrowser,run,window"), { release = true }) -- Super Key to Launch rofi menu
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pkill rofi || true && rofi -show drun -modi drun,filebrowser,run,window"), { description = "Main Menu (APP Launcher)" })
-- hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("xdg-open \"https://\""), { description = "Default browser" })
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pkill rofi || true && ags -t 'overview'"), { description = "Desktop overview (if installed)" })
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:overviewToggle"), { description = "Desktop overview (if installed)" })
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(defaults.term), { description = "Terminal" })
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(defaults.files), { description = "File manager" })
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("kdenlive"), { description = "Kdenlive" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"), { description = "Firefox" })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("foliate"), { description = "Foliate (ebook reader)" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh"), { description = "Clipboard Manager" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code --ozone-platform=x11"), { description = "Visual Studio Code" })
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obsidian --ozone-platform=x11"), { description = "Obsidian" })
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("chromium --new-window --ozone-platform=wayland --app=https://open.spotify.com"), { description = "Spotify" })
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("vesktop"), { description = "Vesktop (Discord)" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("(64gram-desktop|telegram-desktop)"), { description = "Telegram" })
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("fdm"), { description = "Free Download Manager" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(UserScripts .. "/TmuxifierProjects.sh"), { description = "Tmuxifier projects" })

-- FEATURES / EXTRAS
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh"), { description = "Help / cheat sheet" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh"), { description = "Refresh waybar, swaync, rofi" })
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh"), { description = "Toggle blur settings" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh"), { description = "Toggle animations ON/OFF" })
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(UserScripts .. "/Toggle-tuned.sh"), { description = "Toggle tuned daemon" })
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd(UserScripts .. "/SyncDotfiles.sh"), { description = "Sync dotfiles" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(UserScripts .. "/SyncBlog.sh"), { description = "Sync blog" })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.exec_cmd(UserScripts .. "/Jellyfin.sh"), { description = "Media player" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh"), { description = "Toggle Master or Dwindle layout" })
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(UserScripts .. "/ObsidianGenerate.sh"), { description = "Obsidian generator" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a / –autocopy"), { description = "Color picker" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }), { description = "Full screen" })
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd(scriptsDir .. "/Dropterminal.sh " .. defaults.term), { description = "Dropdown terminal" })
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }), { description = "Fake full screen (maximized)" })
hl.bind(mainMod .. " + SPACE", hl.dsp.window.float({ action = "toggle" }), { description = "Float Mode" })
-- All Float Mode (replaces the old `hyprctl dispatch workspaceopt allfloat`,
-- which no longer works in Lua mode — implemented natively instead)
hl.bind(mainMod .. " + ALT + SPACE", function()
    local ws = hl.get_active_workspace()
    local windows = hl.get_workspace_windows(ws.id)
    local anyFloating = false
    for _, w in ipairs(windows) do
        if w.floating then anyFloating = true break end
    end
    local action = anyFloating and "disable" or "enable"
    for _, w in ipairs(windows) do
        hl.dispatch(hl.dsp.window.float({ action = action, window = w.address }))
    end
end, { description = "All Float Mode" })
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh"), { description = "Emoji menu" })

-- Desktop zooming or magnifier
-- Replaces the old `hyprctl keyword cursor:zoom_factor` shell pipeline with
-- direct in-process config access (identical math, no per-press subprocess).
hl.bind(mainMod .. " + ALT + mouse_down", function()
    local z = hl.get_config("cursor.zoom_factor") or 1.0
    local factor = math.max(z, 1) * 2.0
    hl.config({ cursor = { zoom_factor = factor } })
end, { description = "Zoom in" })
hl.bind(mainMod .. " + ALT + mouse_up", function()
    local z = hl.get_config("cursor.zoom_factor") or 1.0
    local factor = math.max(z, 1) / 2.0
    hl.config({ cursor = { zoom_factor = factor } })
end, { description = "Zoom out" })

-- Waybar / Bar related
hl.bind(mainMod .. " + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"), { description = "Toggle hide/show waybar" })
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarStyles.sh"), { description = "Waybar Styles Menu" })
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh"), { description = "Waybar Layout Menu" })

-- FEATURES / EXTRAS (UserScripts)
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(UserScripts .. "/RofiBeats.sh"), { description = "Online music via rofi" })
-- NOTE: the original config bound BOTH of these to SUPER + SHIFT + W (both fire, in order)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperSelect.sh"), { description = "Select wallpaper to apply" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperEffects.sh"), { description = "Wallpaper Effects by imagemagick" })
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(UserScripts .. "/WallpaperRandom.sh"), { description = "Random wallpapers" })
hl.bind(mainMod .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }), { description = "Toggle opacity on active window" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh"), { description = "Search keybinds via rofi" })
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh"), { description = "Hyprland animations menu" })
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd(UserScripts .. "/ZshChangeTheme.sh"), { description = "Change oh-my-zsh theme" })
-- hl.bind("ALT_L", hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh"), { locked = true, non_consuming = true }) -- Change keyboard layout globally
-- hl.bind("SHIFT_L", hl.dsp.exec_cmd(scriptsDir .. "/Tak0-Per-Window-Switch.sh"), { locked = true, non_consuming = true }) -- Change keyboard layout per window
hl.bind(mainMod .. " + CTRL + C", hl.dsp.exec_cmd(UserScripts .. "/RofiCalc.sh"), { description = "Calculator (qalculate)" })

-- For passthrough keyboard into a VM
-- hl.bind(mainMod .. " + ALT + P", hl.dsp.submap("passthru"))
-- hl.define_submap("passthru", function()
--     -- to unbind, see https://wiki.hypr.land/Configuring/Binds/#submaps
-- end)

-- Removed binds
-- hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh"), { description = "Google search using rofi" })
-- hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd(scriptsDir .. "/RofiThemeSelector.sh"), { description = "HyprFlux Rofi Menu Theme Selector" })
-- hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("pkill rofi || true && " .. scriptsDir .. "/RofiThemeSelector-modified.sh"), { description = "Modified Rofi Theme Selector" })
