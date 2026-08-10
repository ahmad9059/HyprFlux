# 06 — Migrating Settings and Variables (`hl.config`)

All option blocks — `general`, `decoration`, `input`, `gestures`, `group`, `misc`, `binds`,
`xwayland`, `render`, `cursor`, `debug`, `layout`, `ecosystem`, `quirks` — become
`hl.config({ ... })` calls. You can call `hl.config()` as many times as you like; each call only
updates what you pass (deep-merge), and it is callable at runtime.

## 6.1 Rule of one-to-one

A hyprlang block converts mechanically:

```lua
-- hyprlang
general {
    gaps_in = 2
    gaps_out = 4
    border_size = 2
    col.active_border = $color12
    col.inactive_border = $color10
    layout = dwindle
    resize_on_border = true
}

-- Lua
hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 4,
        border_size = 2,
        col = {
            active_border = colors.active,      -- from your color module (see 6.4)
            inactive_border = colors.inactive,
        },
        layout = "dwindle",
        resize_on_border = true,
    },
})
```

Nested blocks nest tables: `decoration { blur { ... } }` → `decoration = { blur = { ... } }`.

## 6.2 Type rules that bite

| type | gotcha |
|---|---|
| `bool` | real `true`/`false`, not `yes/no` |
| `int` | plain number; `1.0` is fine but keep integers integer |
| `float` | number with decimals (`scale = 1.5`) |
| `css_gaps` | int **or** `{ top, left, right, bottom }` — `gaps_in = { 0, 4, 0, 4 }` won't work; use the named table form |
| `vec2` | `{ 800, 600 }` table |
| `color` | see 6.4 |
| `gradient` | color, or `{ colors = {...}, angle = 45 }` |
| `str` | quotes; **no `$VAR` expansion**, hyphens → underscores |

## 6.3 HyprFlux `UserSettings.conf` conversion example (excerpt)

```lua
-- hyprlang (UserSettings.conf)                    --> Lua
-- layout { dwindle { ... } }                      --> hl.config({ layout = { dwindle = { ... } } })
hl.config({ layout = { dwindle = { force_split = 2, preserve_split = true } } })

hl.config({
    input = {
        kb_layout = "us",
        repeat_rate = 50,
        repeat_delay = 300,
        numlock_by_default = true,
        touchpad = { natural_scroll = true, disable_while_typing = true },
    },
})

-- REMOVED options: gestures.workspace_swipe / _fingers / _min_fingers
-- Old:  gestures { workspace_swipe = true ... }  →  hl.gesture() (doc 11)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.config({ gestures = { workspace_swipe_distance = 300, workspace_swipe_invert = true } })

hl.config({
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true, vrr = 2,
             enable_swallow = true, swallow_regex = "kitty" },
    binds = { workspace_back_and_forth = true },
    xwayland = { force_zero_scaling = true },
    render = { ... },          -- copy as-is
    cursor = { ... },          -- copy as-is
    debug = { vfr = true },    -- NOTE: was misc:vfr in <0.55
})
```

## 6.4 The color module — `hyprflux-colors.conf` → `hyprflux-colors.lua`

The single most reused file: 17 colors (`$background`, `$foreground`, `$color0`–`$color15`).
Convert it to a **module that returns a table** — then every other file imports it once:

```lua
-- hyprflux-colors.lua
local colors = {
    background = "rgba(1E102Fff)",
    foreground = "rgba(EDE1FFff)",
    color0  = "rgba(2415CCff)",
    color1  = "rgba(E05E8Cff)",
    color2  = "rgba(3DBF82ff)",
    -- ... color3..color15
    color12 = "rgba(7D4AB4ff)",   -- ← used for active_border
    color10 = "rgba(1500E4ff)",   -- ← used for inactive_border
}
return colors
```

```lua
-- user-decorations.lua
local colors = require("hyprflux-colors")
hl.config({
    general = { col = { active_border = colors.color12, inactive_border = colors.color10 } },
})
```

Two migrations notes:
- hyprlang colors `rgb(7D4AB4)` have no alpha → either keep `rgb(...)` form (defaults alpha=ff)
  or normalize to `rgba(7D4AB4ff)` — pick one and be consistent.
- Keep the `.conf` color file for **hyprlock/hypridle** if they reference it (those stay hyprlang
  — hyprlock can't read Lua). Duplicate the palette as a module and a `.conf` if needed.

## 6.5 Runtime toggles (replaces `hyprctl keyword` in scripts)

```lua
-- toggle gaps (equivalent to {3,3,3,3})
hl.bind("SUPER + SHIFT + G", function()
    local g = hl.get_config("general.gaps_in")
    if g.top == 3 then hl.config({ general = { gaps_in = 0 } })
    else                hl.config({ general = { gaps_in = 3 } }) end
end)
```

`hl.get_config("category.key")` returns the underlying type's representation —
`gaps_in = 3` comes back as `{ top = 3, left = 3, right = 3, bottom = 3 }`.

HyprFlux's runtime-toggle scripts (ChangeBlur.sh, ChangeLayout.sh, Animations.sh, GameMode.sh,
Refresh.sh) should be converted to either pure-Lua binds (fastest) or `hyprctl eval` one-liners
(doc 14 §14.6).

## 6.6 Validation for this phase

```bash
luac -p hyprland.lua && Hyprland --config hyprland.lua --verify-config
hyprctl getoption general:gaps_in          # spot-check values live
hyprctl eval 'print(hl.get_config("general.gaps_in").top)'   # REPL check
```

Next: [07-migrating-keybinds.md](07-migrating-keybinds.md)
