# 10 — Migrating Autostart and Environment (`hl.on`, `hl.env`)

## 10.1 Autostart — `exec-once` → events

```lua
-- hyprlang:  exec-once = waybar
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("nm-applet")
end)
```

- `hl.exec_cmd()` spawns **asynchronously** — no `&` / `disown` needed.
- Multiple commands in one string still work (`hl.exec_cmd("waybar & hyprpaper")`) but prefer
  one call per process for reliability.
- Spawn on logout: `hl.on("hyprland.shutdown", function() ... end)`.
- Per-bind exec (hyprlang `bind = ..., exec, ...`) → `hl.dsp.exec_cmd(cmd)`; raw (no `sh -c`)
  → `hl.dsp.exec_raw(cmd)`.
- **Systemd-managed services belong in systemd**, not the config (HyprFlux already does this for
  the refresh-rate service — keep it that way).

### HyprFlux `Startup_Apps.conf` → `startup-apps.lua`

```lua
local Home = os.getenv("HOME")
local wallDIR = Home .. "/Pictures/wallpapers"
local lock = "hyprlock"        -- matches the $lock var used by scripts

hl.on("hyprland.start", function()
    hl.exec_cmd(Home .. "/.config/hypr/initial-boot.sh")       -- first-boot theming (self-guarded)
    hl.exec_cmd("awww-daemon")                                  -- wallpaper daemon
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(Home .. "/.config/hypr/scripts/Polkit.sh")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("swaync")
    hl.exec_cmd("waybar")
    hl.exec_cmd("qs")                                           -- quickshell
    hl.exec_cmd("cliphist store")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("hypridle")                                     -- stays hyprlang config
end)
```

The live machine also has `systemctl --user restart hypr-refresh-rate.service` — keep it out of
Lua (it's a systemd unit already).

## 10.2 `hl.env` — environment variables

```lua
hl.env("KEY", "VALUE")
hl.env("KEY", "VALUE", true)   -- 3rd arg: export over dbus (was envd)
```

Rules:

1. Set **before** Display Server initialization — order matters: put all `hl.env` calls at the
   top of `hyprland.lua` or in the first `require`'d module.
2. **No `$VAR` expansion.** `hl.env("HYPRSHOT_DIR", "$HOME/Pictures")` creates a literal `$HOME`
   directory. Use `os.getenv`:
   ```lua
   hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")
   ```
3. Prefer `os.getenv("XDG_RUNTIME_DIR")` for sockets:
   ```lua
   hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/ssh-agent.socket")
   ```
4. Avoid `/etc/environment` (leaks Wayland vars into Xorg sessions).
5. uwsm users: `~/.config/uwsm/env` for theming/cursor/NVIDIA, `~/.config/uwsm/env-hyprland`
   for `HYPR*`/`AQ_*`.

### HyprFlux `ENVariables.conf` → `env-variables.lua` (excerpt with live-machine changes)

```lua
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")                      -- live machine: 24
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- NVIDIA dGPU + AMD iGPU hybrid (live-machine values — keep, they fix the login crash loop):
hl.env("AQ_DRM_DEVICES", "/dev/dri/card2:/dev/dri/card1")   -- AMD iGPU first
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
```

Keep commented-out NVIDIA-only vars (`GBM_BACKEND=nvidia-drm`, `LIBVA_DRIVER_NAME=nvidia`) as
comments with the same guidance.

## 10.3 Ordering in the target file

Recommended `hyprland.lua` bootstrap order (matches today's `hyprland.conf` source order):

```lua
local Home = os.getenv("HOME")

require("UserConfigs.env-variables")    -- hl.env first
require("UserConfigs.user-defaults")    -- locals (term, files, ...)
require("UserConfigs.user-settings")
require("UserConfigs.user-decorations") -- includes color module import
require("UserConfigs.user-animations")
require("configs.keybinds")             -- default binds
require("UserConfigs.user-keybinds")    -- user binds (later = can rely on order? no — binds don't conflict by order except catchall/submaps; keep as-is order)
require("UserConfigs.laptops")
require("UserConfigs.window-rules")
require("UserConfigs.startup-apps")     -- autostart last
require("monitors")                     -- nwg-displays
require("workspaces")
```

> Binds are *not* order-dependent except for catchall and submaps; rules *are* order-dependent —
> keep `window-rules.lua` loaded after settings but its internal order unchanged.

Next: [11-migrating-animations-and-devices.md](11-migrating-animations-and-devices.md)
