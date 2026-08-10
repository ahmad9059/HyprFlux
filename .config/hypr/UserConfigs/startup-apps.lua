-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Startup apps (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/Startup_Apps.conf (9 active exec-once)
-- Wiki: https://wiki.hypr.land/Configuring/Autostart/
--
-- hl.exec_cmd() spawns asynchronously — no `&` / disown needed.
-- Systemd-managed services belong in systemd, not here.

local Home = os.getenv("HOME")
local scriptsDir = Home .. "/.config/hypr/scripts"
local UserScripts = Home .. "/.config/hypr/UserScripts"

local wallDIR = Home .. "/Pictures/wallpapers"
local lock = scriptsDir .. "/LockScreen.sh"
local AwwwRandom = UserScripts .. "/WallpaperAutoChange.sh"
local livewallpaper = "" -- set by WallpaperSelect.sh for video wallpapers (mpvpaper)

hl.on("hyprland.start", function()
    -- wallpaper stuff
    hl.exec_cmd("awww-daemon --format xrgb")
    -- hl.exec_cmd("mpvpaper '*' -o \"load-scripts=no no-audio --loop\"" .. livewallpaper)

    -- wallpaper random (every 30 minutes)
    -- hl.exec_cmd(AwwwRandom .. " " .. wallDIR)

    -- Startup
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Polkit (Polkit Gnome / KDE)
    hl.exec_cmd(scriptsDir .. "/Polkit.sh")

    -- startup apps
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("swaync")
    -- hl.exec_cmd("ags")
    -- hl.exec_cmd("blueman-applet")
    -- hl.exec_cmd("rog-control-center")
    hl.exec_cmd("waybar")
    hl.exec_cmd("qs") -- quickshell, AGS Desktop Overview alternative

    -- clipboard manager
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Rainbow borders
    -- hl.exec_cmd(UserScripts .. "/RainbowBorders.sh")

    -- Starting hypridle to start hyprlock
    hl.exec_cmd("hypridle")

    -- live machine: refresh-rate daemon (165Hz AC / 60Hz battery) is a
    -- systemd user service; restart it so login always pairs with this config
    hl.exec_cmd("systemctl --user restart hypr-refresh-rate.service")
end)

-- Here are a list of features available but disabled by default
-- hl.exec_cmd("awww-daemon --format xrgb && awww img " .. Home .. "/Pictures/wallpapers/mecha-nostalgia.png") -- persistent wallpaper

-- gnome polkit for nixos
-- hl.exec_cmd(scriptsDir .. "/Polkit-NixOS.sh")

-- xdg-desktop-portal-hyprland (should be auto starting; force start if needed)
-- hl.exec_cmd(scriptsDir .. "/PortalHyprland.sh")
