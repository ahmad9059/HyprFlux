# 07 — Migrating Keybinds (`hl.bind`)

HyprFlux has **152 active binds** — the biggest part of the migration. This document covers the
full `hl.bind` API and the exact patterns to convert HyprFlux's three bind files.

## 7.1 Basic syntax

```lua
hl.bind(keys, dispatcher, options?)
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("firefox"))
```

- `keys` — string like `"SUPER + SHIFT + Q"`, `"XF86AudioRaiseVolume"`, `"code:28"` (keycode),
  `"mouse:272"` (mouse), `"switch:on:Lid Switch"`, `"catchall"`.
- `dispatcher` — a `hl.dsp.*` action description **or** a Lua function.
- `options` — table of flags (7.4).

## 7.2 Dispatcher catalog (the ones HyprFlux uses)

```lua
hl.dsp.exec_cmd("rofi -show drun")                        -- exec
hl.dsp.exec_raw("foo")                                    -- execr (no sh -c)
hl.dsp.window.close()                                     -- killactive
hl.dsp.window.kill({ window = "class:foo" })              -- killwindow
hl.dsp.focus({ workspace = 1 })                           -- workspace
hl.dsp.focus({ workspace = "e+1" })                       -- workspace +1
hl.dsp.focus({ workspace = "name:Web" })                  -- named
hl.dsp.workspace.toggle_special("magic")                  -- special
hl.dsp.window.move({ workspace = 3 })                     -- movetoworkspace
hl.dsp.window.move({ workspace = "special:3" })           -- scratchpad
hl.dsp.window.move({ direction = "l" })                   -- movewindow
hl.dsp.window.move({ monitor = "DP-1" })                  -- movewindowtomonitor
hl.dsp.window.swap({ direction = "r" })                   -- swapwindow
hl.dsp.window.float({ action = "toggle" })                -- togglefloating
hl.dsp.window.fullscreen({ action = "toggle" })           -- fullscreen
hl.dsp.window.pseudo({ action = "toggle" })               -- pseudo
hl.dsp.focus({ direction = "u" })                         -- movefocus
hl.dsp.window.cycle_next({ next = true })                 -- cyclenext
hl.dsp.focus({ window = "class:thunar" })                 -- focuswindow
hl.dsp.focus({ monitor = "DP-1" })                        -- focusmonitor
hl.dsp.layout("togglesplit")                              -- layoutmsg
hl.dsp.window.set_prop({ prop = "no_anim", value = "1" }) -- setprop
hl.dsp.window.tag({ tag = "+code" })                      -- tagwindow
hl.dsp.window.pin({ action = "toggle" })                  -- pin
hl.dsp.dpms({ action = "on" })                            -- dpms
hl.dsp.submap("resize")                                   -- submap
hl.dsp.exit()                                             -- exit (prefer hyprshutdown)
hl.dsp.window.drag() / hl.dsp.window.resize()             -- mouse binds
hl.dsp.pass({ window = "class:^...(OBS)$" })              -- global keybinds
hl.dsp.global("app:shortcut")                             -- dbus global shortcut
hl.dsp.window.resize({ x = 10, y = 0, relative = true })  -- resizeactive
hl.dsp.window.move({ x = 0, y = 0, relative = true })     -- moveactive
hl.dsp.window.alter_zorder({ mode = "top" })              -- alterzorder
```

## 7.3 Multiple actions per key

```lua
hl.bind("SUPER + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
```

## 7.4 Bind flags (from `bindl`/`bindr`/`bindt`/`binds`/`bindm`)

```lua
hl.bind(keys, dispatcher, {
    locked = true,          -- was bindl  (works when locked/inhibited)
    release = true,         -- was bindr  (on key release)
    transparent = true,     -- was bindt  (can't be shadowed)
    repeating = true,       -- was binds  (repeat while held)
    mouse = true,           -- was bindm  (mouse binds)
    click = true,           -- was bindc  (release within drag_threshold)
    drag = true,            -- was bindg  (release outside drag_threshold)
    non_consuming = true,   -- pass key to app too
    auto_consuming = true,  -- pass to app if dispatch fails
    ignore_mods = true,     -- ignore modifiers
    description = "text",   -- show in hyprctl binds
    submap_universal = true,-- active in all submaps
    dont_inhibit = true,    -- bypass app inhibit requests
    device = { inclusive = true, list = { "dev1" } },  -- per-device
})
```

HyprFlux examples:

```lua
-- bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

-- binds = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
```

## 7.5 Keycode / special keys

```lua
hl.bind("SUPER + code:28", ...)                 -- keycode 28 = t
hl.bind("SUPER + mouse:272", ...)               -- LMB; 273 = RMB, 274 = MMB
hl.bind("SUPER + mouse_down", ...)              -- wheel (also mouse_up/left/right)
hl.bind("ALT + ALT_L", hl.dsp.exec_cmd("x"), { release = true })  -- modkey-only bind
hl.bind("switch:Lid Switch", ...)               -- toggled switch
hl.bind("switch:on:Lid Switch", ...)            -- on-transition
```

Find keycodes/names with `wev`. `hyprctl devices` lists switches.

## 7.6 `hl.unbind`

```lua
hl.unbind("SUPER + O")        -- case-sensitive exact match
```

## 7.7 Loops — the HyprFlux workspace binds

`configs/Keybinds.conf` has ~30 workspace binds (SUPER/SHIFT/CTRL × 1-10, keycode-based).
All of it collapses to:

```lua
local mainMod = "SUPER"
for i = 1, 10 do
    local key = tostring(i % 10)              -- "1".."9","0"
    hl.bind(mainMod .. " + " .. key,       hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. key,  hl.dsp.window.move({ workspace = "special:" .. tostring(i) }))
end
```

Note: old config binds by keycode (so the layout doesn't matter); `code:` prefix preserves that
behavior: `hl.bind(mainMod .. " + code:" .. (i % 10), ...)` — pick per repo policy. Keysym-based
binds are more readable; `resolve_binds_by_sym = 1` in `input` keeps them layout-independent.

## 7.8 Mouse binds (HyprFlux: SUPER+LMB move, SUPER+RMB resize)

```lua
-- bindm = SUPER, mouse:272, movewindow   →  in Lua, interactive drag:
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
```

Click-vs-drag distinction (HyprFlux's float-on-click patterns):

```lua
hl.config({ binds = { drag_threshold = 10 } })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),  { mouse = true, drag = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.float(), { mouse = true, click = true })
```

## 7.9 Submaps (used in HyprFlux for resize/KeyHints flows)

```lua
hl.bind("ALT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("right",  hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)
```

- Always provide an exit (escape → `submap("reset")`).
- Emergency exit: `hyprctl eval 'hl.dispatch(hl.dsp.submap("reset"))'`.
- `hl.bind("catchall", hl.dsp.submap("reset"))` = catch-all to block/exit on unknown keys.
- Nesting and auto-close on dispatch supported (see appendix §2).

## 7.10 Per-device binds + `device:` blocks (HyprFlux Laptops.conf)

```lua
-- hyprlang:  device { name = $Touchpad_Device  natural_scroll = true }
hl.device({ name = "synaptics_touchpad", natural_scroll = true, enabled = true })

-- hyprlang:  bind = , XF86TouchpadToggle, exec, ...
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/TouchPad.sh"), { description = "Toggle touchpad" })

-- device-scoped binds:
hl.bind("SUPER + F6", hl.dsp.exec_cmd("screen-shot.sh"), { device = { inclusive = true, list = { "at-translated-set-2-keyboard" } } })
```

`name` comes from `hyprctl devices`. Device bind list: names or `tags` (set via
`hl.device({ name, tags = "gaming" })`).

## 7.11 Converting HyprFlux's bind files — recipe

1. Copy each `bind = ...` line into a table: `{ key = "...", action = "...", args = {...} }`.
2. Map the action string through the 5.3 table to `hl.dsp.*`.
3. Translate flags (`bindl`/`binds`/`bindr`/`bindm` → option table).
4. Replace `$VAR` refs with locals/concat.
5. Run `hyprctl binds` before/after and diff counts and names.

Example line-by-line (from `configs/Keybinds.conf`):

```lua
-- bind = SUPER, Q, exec, kitty
hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"), { description = "Terminal" })

-- bind = SUPER, D, exec, rofi -show drun
hl.bind("SUPER + D", hl.dsp.exec_cmd("rofi -show drun"))

-- bind = SUPER, V, togglefloating
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))

-- bind = SUPER, F, fullscreen, 0
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }))

-- bind = SUPER, P, pseudo, 0
hl.bind("SUPER + P", hl.dsp.window.pseudo({ action = "toggle" }))

-- bindm = SUPER, mouse:272, movewindow
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- bind = SUPER, L, exec, hyprlock
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"))
```

Next: [08-migrating-monitors-and-workspaces.md](08-migrating-monitors-and-workspaces.md)
