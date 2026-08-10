# 11 — Migrating Animations and Devices (`hl.curve`, `hl.animation`, `hl.device`, `hl.gesture`)

## 11.1 Beziers → `hl.curve`

```lua
-- hyprlang:  bezier = wind, 0.05, 0.9, 0.1, 1.05
hl.curve("wind", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
```

**New in Lua: springs** — physics-based curves:

```lua
hl.curve("rubber", { type = "spring", mass = 1, stiffness = 70, dampening = 10 })
```

- More stiffness = more speed; more dampening = less bounce. Keep `mass = 1`.

HyprFlux `UserAnimations.conf` beziers (7) convert to:

```lua
hl.curve("wind",      { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05} } })
hl.curve("winIn",     { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05} } })
hl.curve("winOut",    { type = "bezier", points = { {0.0, 0.0},  {0.58, 1.0} } })
hl.curve("liner",     { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05} } })
hl.curve("overshot",  { type = "bezier", points = { {0.13, 0.99}, {0.11, 1.29} } })
hl.curve("smoothOut", { type = "bezier", points = { {0.36, 0.0},  {0.66, -0.56} } })
hl.curve("smoothIn",  { type = "bezier", points = { {0.25, 1.0},  {0.5, 1.0} } })
```

## 11.2 Animations → `hl.animation`

```lua
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "wind", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "my_spring", style = "slide" })
hl.animation({ leaf = "fade", enabled = false })
```

- `leaf` — see the animation tree below.
- `speed` — in **ds** (1 ds = 100 ms). hyprlang `animation = windows, 1, 7, wind, slide` →
  `speed = 7`.
- `bezier` **or** `spring` names a curve registered with `hl.curve`.
- `style` — per-leaf styles (`slide`, `popin`, `slidevert`, `fade`, `slidefade`,
  `slidefadevert`, `once`, `loop`, `popin 80%`, `slidefade 20%`, `slide left`...).

### Animation tree (leaves)

```
global
  windows            (slide|popin|gnomed)      ← windowsMove = moving/dragging/resizing
    windowsIn        windowsOut  windowsMove
  layers             (slide|popin|fade)
    layersIn  layersOut
  fade
    fadeIn fadeOut fadeSwitch fadeShadow fadeGlow fadeDim
    fadeLayers (fadeLayersIn fadeLayersOut)
    fadePopups (fadePopupsIn fadePopupsOut)
    fadeDpms
  border  borderangle  shadowangle  glowangle
  workspaces         (slide|slidevert|fade|slidefade|slidefadevert)
    workspacesIn  workspacesOut
    specialWorkspace (specialWorkspaceIn specialWorkspaceOut)
  zoomFactor  monitorAdded
```

Unset leaves inherit from their parent (`windows` → `windowsIn/Out/Move`).

### HyprFlux `UserAnimations.conf` → `user-animations.lua`

```lua
hl.config({ animations = { enabled = true } })

hl.animation({ leaf = "windows",       enabled = true, speed = 7, bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 7, bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3, bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 5, bezier = "liner",     style = "slide" })
hl.animation({ leaf = "border",        enabled = true, speed = 4, bezier = "liner" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 4, bezier = "liner",     style = "loop" })
hl.animation({ leaf = "fade",          enabled = true, speed = 4, bezier = "liner" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5, bezier = "overshot",  style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5, bezier = "overshot",  style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5, bezier = "smoothOut", style = "slide" })
```

> `style = "loop"` on `*angle` leaves forces constant rendering at refresh rate — CPU/GPU cost
> even with animations disabled. Only keep if the animated border gradient is wanted.

## 11.3 Animation presets (`animations/*.conf` → `animations/*.lua`)

The 16 preset files each contain an `animations { }` block. Convert each to a Lua module that
just registers curves + animations. `Animations.sh` switches presets by copying files — update it
to copy `.lua` modules and `require` by a stable name:

```lua
-- animations/00-default.lua
hl.curve(...)
hl.animation(...)
-- ...
-- hyprland.lua
require("animations/00-default")        -- or a symlink/preset-switch variable
```

## 11.4 Devices — `device { }` → `hl.device`

```lua
-- hyprlang:
-- device {
--     name = $Touchpad_Device
--     natural_scroll = true
--     disable_while_typing = true
-- }
hl.device({ name = "synaptics_touchpad", natural_scroll = true, disable_while_typing = true })
```

- `name` from `hyprctl devices`.
- Any `input.*` option is valid per-device **except** window-management ones
  (`follow_mouse`, `mouse_refocus`, `float_switch_override_focus`, `force_no_accel`).
- Extra per-device fields: `enabled` (bool), `keybinds` (bool), `tags` (string list for
  device-scoped binds).
- Laptop keyboard layout handling: per-device `kb_layout` does not change the keybind keymap —
  set `resolve_binds_by_sym = 1` for symbol-based binds.

## 11.5 Gestures — the removed options

**Removed in 0.55:** `gestures.workspace_swipe`, `gestures.workspace_swipe_fingers`,
`gestures.workspace_swipe_min_fingers`. The new API:

```lua
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "vertical",   action = "special" })
```

HyprFlux `UserSettings.conf` currently sets `gestures { workspace_swipe = true,
workspace_swipe_fingers = 3, ... }` — replace with a `hl.gesture()` call. The remaining
`gestures.workspace_swipe_*` *distance/invert/forever/cancel_ratio* options still exist inside
`hl.config({ gestures = { ... } })` and can stay.

## 11.6 Validation

```bash
Hyprland --config hyprland.lua --verify-config
hyprctl getoption animations:enabled
hyprctl getoption decoration:shadow:enabled
```

Next: [12-automated-tools-and-lsp.md](12-automated-tools-and-lsp.md)
