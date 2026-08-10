# 14 — Advanced Lua Patterns (what you can't do in hyprlang)

The whole point of the migration: capabilities hyprlang will never have. Use these to *delete*
scripts, not just port them.

## 14.1 Rule handles — toggle without reload

```lua
local floatKitty = hl.window_rule({ name = "float-kitty", match = { class = "kitty" }, float = true })

hl.bind("SUPER + SHIFT + F", function()
    floatKitty:set_enabled(not floatKitty:is_enabled())
end)
```

HyprFlux's `Refresh.sh`/gamemode flows that flip `hyprctl keyword windowrule` can become handles.

## 14.2 Events — replace socket2 scripts

```lua
-- old: while read line < socket2; do case "$line" in fullscreen>>*) ...; esac; done
hl.on("window.fullscreen", function(w)
    if w.fullscreen then
        hl.dispatch(hl.dsp.window.float({ action = "set", window = w.address }))
    end
end)

hl.on("monitor.added", function(m)
    hl.notification.create({ text = "Monitor connected: " .. m.name, timeout = 5000, icon = "ok" })
end)
```

Full event list (26): see appendix §12. The ones HyprFlux scripts care about:
`hyprland.start`, `hyprland.shutdown`, `window.open`, `window.close`, `window.active`,
`window.title`, `window.fullscreen`, `workspace.active`, `workspace.move_to_monitor`,
`monitor.added`, `monitor.removed`, `monitor.focused`, `config.reloaded`, `keybinds.submap`.

## 14.3 Timers — replace cron/anacron hacks

```lua
local t = hl.timer(function()
    hl.exec_cmd("$HOME/.config/hypr/scripts/WallpaperAutoChange.sh")   -- → use os.getenv!
end, { timeout = 30 * 60 * 1000, type = "repeat" })
t:set_enabled(false)
```

## 14.4 Dynamic config toggles (gamemode, blur, gaps)

```lua
-- HyprFlux GameMode.sh equivalent, no script, no hyprctl:
local gamemodeActive = false
hl.bind("SUPER + SHIFT + G", function()
    gamemodeActive = not gamemodeActive
    if gamemodeActive then
        hl.config({
            general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
            decoration = { rounding = 0, shadow = { enabled = false }, blur = { enabled = false } },
            animations = { enabled = false },
        })
    else
        hl.exec_cmd("hyprctl reload")     -- or re-apply the saved config values
    end
end)
```

## 14.5 Conditional binds (layout-aware, window-aware)

```lua
-- layoutmsg swapcol only when dwindle/master — avoid runtime errors on other layouts
hl.bind("SUPER + CTRL + S", function()
    local ws = hl.get_active_workspace()
    if ws.tiled_layout == "dwindle" or ws.tiled_layout == "master" then
        hl.dispatch(hl.dsp.layout("swapcol l"))
    end
end)

-- window-aware action
hl.bind("SUPER + X", function()
    local w = hl.get_active_window()
    if w and w.class == "htop" then
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
    else
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    end
end)
```

## 14.6 Script bridge — `hyprctl eval` from shell

Scripts that *must* stay shell can still use Lua:

```bash
hyprctl eval 'hl.config({ general = { gaps_in = 0 } })'
hyprctl eval 'hl.dispatch(hl.dsp.window.float({ action = "toggle" }))'
hyprctl eval 'local w = hl.get_active_window(); if w then print(w.class) end'
```

HyprFlux script migration table is in doc 15 §7.

## 14.7 Percent-based resize/move (no typed dispatcher)

`resizeactive 50% 50%` has no typed equivalent — resolve against the window:

```lua
hl.bind("SUPER + CTRL + R", function()
    local w = hl.get_active_window()
    if not w then return end
    hl.dispatch(hl.dsp.window.resize({
        x = w.size.w * 0.5,
        y = w.size.h * 0.5,
        relative = true,
    }))
end)
```

## 14.8 Performance rules (compositor safety)

1. **Never block in bind callbacks**: no `io.popen`, `wl-paste`, `xclip`, `sleep`, network I/O,
   heavy loops. Use `hl.dsp.exec_cmd()` (async spawn) or `hl.timer`.
2. If you must probe (e.g. `hyprctl`-style queries), bound-wait via `timeout` or cache results.
3. Prefer direct `hl.dispatch(hl.dsp...)` over `exec_cmd("hyprctl dispatch ...")` — one less
   process per keypress.
4. Avoid `style = "loop"` on `*angle` animations (constant rendering).
5. `hl.exec_scheduled_prop_refresh_immediately()` only when needed — overuse slows the loop.

## 14.9 Modular color/theming (HyprFlux pattern)

```lua
-- themes/red.lua
local base = require("hyprflux-colors")
base.color12 = "rgba(FF5555ff)"
return base

-- theme switcher bind (replaces RofiThemeSelector for hyprland side)
hl.bind("SUPER + SHIFT + T", function()
    local theme = require("themes." .. "red")     -- dynamic require
    hl.config({ general = { col = { active_border = theme.color12 } } })
end)
```

## 14.10 Version-guarded config

```lua
local v = hl.version()
if v >= "0.56.0" then
    require("advanced-features")
end
```

## 14.11 Minified "split-monitor-workspaces" in <50 lines

```lua
for i, m in ipairs(hl.get_monitors()) do
    for w = 1, 5 do
        local wsId = m.id * 10 + w
        hl.bind(mainMod .. " + " .. tostring(w), function()
            hl.dispatch(hl.dsp.focus({ workspace = wsId, on_current_monitor = true }))
        end)
    end
end
```

Next: [15-hyprflux-specific-plan.md](15-hyprflux-specific-plan.md)
