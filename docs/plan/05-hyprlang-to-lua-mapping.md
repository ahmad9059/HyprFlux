# 05 — hyprlang → Lua Master Mapping

The definitive cheat sheet. Every hyprlang construct and its Lua equivalent, with worked examples.
Section numbers reference the detailed docs.

---

## 5.1 Top-level statements

| hyprlang | Lua | Where |
|---|---|---|
| `category { key = value }` (general, decoration, input, ...) | `hl.config({ category = { key = value } })` | doc 06 |
| `$VAR = value` | `local VAR = value` (+ `..` concat) | doc 02 |
| `source = path.conf` | `require("path")` | doc 03 |
| `bind = ...` | `hl.bind("MODS + KEY", dispatcher)` | doc 07 |
| `bindl / bindr / bindt / binds / bindm` | `hl.bind(..., { locked/release/transparent/repeating/mouse = true })` | doc 07 |
| `unbind = MODS, KEY` | `hl.unbind("MODS + KEY")` | doc 07 |
| `monitor = ...` | `hl.monitor({ ... })` | doc 08 |
| `windowrule = ...` | `hl.window_rule({ ... })` | doc 09 |
| `layerrule = ...` | `hl.layer_rule({ ... })` | doc 09 |
| `workspacerule = ...` | `hl.workspace_rule({ ... })` | doc 08 |
| `exec-once = cmd` | `hl.on("hyprland.start", function() hl.exec_cmd(cmd) end)` | doc 10 |
| `exec = cmd` (per-bind) | `hl.dsp.exec_cmd(cmd)` | doc 10 |
| `execr` (raw, no sh -c) | `hl.dsp.exec_raw(cmd)` | doc 10 |
| `env = KEY, VALUE` | `hl.env("KEY", "VALUE")` | doc 10 |
| `device { name = ... }` | `hl.device({ name = "...", ... })` | doc 11 |
| `bezier = name, x1, y1, x2, y2` | `hl.curve("name", { type = "bezier", points = { {x1, y1}, {x2, y2} } })` | doc 11 |
| `animation = leaf, enabled, speed, curve, style` | `hl.animation({ leaf = "leaf", enabled = bool, speed = n, bezier/spring = "curve", style = "style" })` | doc 11 |
| `gestures { workspace_swipe* }` | `hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })` (old 3 options **removed**) | doc 11 |
| `submap = name` + binds | `hl.dsp.submap(name)` + `hl.define_submap(name, function() ... end)` | doc 07 |
| `plugin { section = ... }` | `hl.plugin.<name>({ ... })` (per-plugin) | doc 16 |
| `decoration:blur:...`, hyphenated keys | underscores: `decoration.blur.enabled` | doc 16 |

## 5.2 Binds — variants & flags

| hyprlang | Lua flag |
|---|---|
| `bind` | *(default)* |
| `bindl` (works on lockscreen) | `{ locked = true }` |
| `bindr` (on release) | `{ release = true }` |
| `bindt` (transparent) | `{ transparent = true }` |
| `binds` (repeating) | `{ repeating = true }` |
| `bindm` (mouse) | `{ mouse = true }` |
| `bindc` (click) | `{ click = true }` + `binds.drag_threshold` |
| `bindg` (drag) | `{ drag = true }` + `binds.drag_threshold` |
| `bind, , submap, ...` | `hl.dsp.submap("name")` |

```lua
-- hyprlang:  bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

-- hyprlang:  bindm = SUPER, mouse:272, movewindow
hl.bind("SUPER + mouse:272", hl.dsp.window.move({ direction = "l" }), { mouse = true })
```

## 5.3 Common dispatchers — old dispatch string → `hl.dsp.*`

| `hyprctl dispatch ...` | Lua |
|---|---|
| `exec` | `hl.dsp.exec_cmd(cmd)` |
| `execr` | `hl.dsp.exec_raw(cmd)` |
| `killactive` | `hl.dsp.window.close()` |
| `killwindow` | `hl.dsp.window.kill({ window = selector })` |
| `closewindow` | `hl.dsp.window.close({ window = selector })` |
| `workspace N` | `hl.dsp.focus({ workspace = N })` |
| `workspace name:Web` | `hl.dsp.focus({ workspace = "name:Web" })` |
| `special:name` / `togglespecialworkspace` | `hl.dsp.workspace.toggle_special("name")` |
| `moveworkspacetomonitor` | `hl.dsp.workspace.move({ workspace?, monitor })` |
| `swapactiveworkspaces` | `hl.dsp.workspace.swap_monitors({ monitor1, monitor2 })` |
| `movewindow` / `movewindowtomonitor` | `hl.dsp.window.move({ direction })` / `hl.dsp.window.move({ monitor })` |
| `movetoworkspace` | `hl.dsp.window.move({ workspace = N })` |
| `movetoworkspacesilent` | `hl.dsp.window.move({ workspace = N .. " silent" })` (or workspace + silent option) |
| `swapwindow` | `hl.dsp.window.swap({ direction })` |
| `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `fullscreen` | `hl.dsp.window.fullscreen({ action = "toggle" })` |
| `fullscreenstate` | `hl.dsp.window.fullscreen_state({ internal, client, action? })` |
| `pseudo` | `hl.dsp.window.pseudo({ action = "toggle" })` |
| `focusmonitor` | `hl.dsp.focus({ monitor = ... })` |
| `focuswindow` | `hl.dsp.focus({ window = selector })` |
| `movefocus` | `hl.dsp.focus({ direction = "l" })` |
| `cyclenext` | `hl.dsp.window.cycle_next({ next = true })` |
| `layoutmsg` | `hl.dsp.layout("message")` |
| `setprop` | `hl.dsp.window.set_prop({ prop, value, window? })` |
| `tagwindow` | `hl.dsp.window.tag({ tag, window? })` |
| `pin` | `hl.dsp.window.pin({ action = "toggle" })` |
| `dpms` | `hl.dsp.dpms({ action = "on"/"off" })` |
| `exit` | `hl.dsp.exit()` (prefer `hyprshutdown` / `uwsm stop`) |
| `submap` | `hl.dsp.submap("name")` |
| `resizeactive` / `moveactive` | `hl.dsp.window.resize({ x, y, relative? })` / `hl.dsp.window.move({ x, y, relative? })` |
| `renameworkspace` | `hl.dsp.workspace.rename({ workspace, name? })` |
| `denywindowfromgroup` | `hl.dsp.window.deny_from_group({ action? })` |
| `globalshortcuts` | `hl.dsp.global("app:shortcut")` |
| `pass` | `hl.dsp.pass({ window? })` |
| `alterzorder` | `hl.dsp.window.alter_zorder({ mode = "top"/"bottom" })` |

Percent-based `resizeactive`/`moveactive` (e.g. `moveactive 50% 50%`) have **no typed
equivalent** — emit a closure that resolves the percentage against the window/monitor
(doc 14 §14.7).

## 5.4 Monitors

| hyprlang | Lua |
|---|---|
| `monitor = eDP-1, 2560x1440@165, 0x0, 1` | `hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })` |
| `monitor = , preferred, auto, 1` (fallback) | `hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })` |
| `monitor = X, disable` | `hl.monitor({ output = "X", disabled = true })` |
| `monitor = X, 1920x1080, auto, 1, mirror, Y` | `hl.monitor({ output = "X", mode = "1920x1080", position = "auto", scale = 1, mirror = "Y" })` |
| `monitor = X, 1920x1080, auto, 1, transform, 1` | `... transform = 1` |
| `monitor = X, 1920x1080, auto, 1, bitdepth, 10` | `... bitdepth = 10` |
| `monitor = X, ..., vrr, 2` | `... vrr = 2` |
| `monitor = X, ..., cm, wide` | `... cm = "wide"` |
| reserved area | `hl.monitor({ output = "X", reserved_area = { top = 10, bottom = 10 } })` |

## 5.5 Window rules

```lua
-- hyprlang:  windowrule = float, class:(firefox|chrome)
hl.window_rule({ match = { class = "^(firefox|chrome)$" }, float = true })

-- hyprlang:  windowrulev2 = workspace 2 silent, class:(kitty)
hl.window_rule({ match = { class = "kitty" }, workspace = "2 silent" })

-- hyprlang:  windowrule = opacity 0.8 0.7, class:(kitty)
hl.window_rule({ match = { class = "kitty" }, opacity = "0.8 0.7" })

-- hyprlang:  windowrule = size 800 600, class:(thunar)
hl.window_rule({ match = { class = "thunar" }, size = { 800, 600 } })

-- hyprlang:  windowrulev2 = center, class:(.*)
hl.window_rule({ match = { class = ".*" }, center = true })

-- hyprlang:  windowrule = move 100 100, class:(obsidian)
hl.window_rule({ match = { class = "obsidian" }, move = { 100, 100 } })
```

**Old syntax element → new key map** (hyprlang `RULE, VALUE, CLASS` order):

| hyprlang rule | Lua effect |
|---|---|
| `float` / `tile` | `float = true` / `tile = true` |
| `fullscreen` / `maximize` | `fullscreen = true` / `maximize = true` |
| `center` | `center = true` |
| `size WxH` | `size = { W, H }` |
| `move X Y` | `move = { X, Y }` |
| `workspace N` / `workspace N silent` | `workspace = "N"` / `"N silent"` |
| `monitor M` | `monitor = "M"` |
| `pin` | `pin = true` |
| `opacity A B C` | `opacity = "A B C"` (+` override` suffix per value) |
| `border N` | `border_size = N` |
| `noanim` | `no_anim = true` |
| `noblur` | `no_blur = true` |
| `noshadow` | `no_shadow = true` |
| `noborder` | `decorate = false` |
| `rounding N` | `rounding = N` |
| `animation NAME [STYLE]` | `animation = "NAME [STYLE]"` |
| `idleinhibit focus/fullscreen/always` | `idle_inhibit = "..."` |
| `suppressevent ...` | `suppress_event = "..."` |
| `group ...` | `group = "..."` |
| `stayfocused` | `stay_focused = true` |
| `noinitialfocus` | `no_initial_focus = true` |
| `nofocus` | `no_focus = true` |
| `nomaxsize` | `no_max_size = true` |
| `maxsize W H` | `max_size = { W, H }` |
| `minsize W H` | `min_size = { W, H }` |
| `dimaround` | `dim_around = true` |
| `bordercolor COL` | `border_color = "COL"` |
| `xray 1` | `xray = true` |
| `immediate` | `immediate = true` |
| `forceinput` | `allows_input = true` |
| `syncfullscreen` | `sync_fullscreen = true` |
| `opaque` | `opaque = true` |
| `keepaspectratio` | `keep_aspect_ratio = true` |
| `noinitialworkspace` | (handled by workspace rules / `no_initial_focus`) |
| `persistentworkspace` | (workspace rule `persistent = true`) |
| `noallowtearing` | (not a rule; set `allow_tearing` per window via `immediate`/tearing options) |
| `focusonactivate` | `focus_on_activate = true` |
| `no_shortcuts_inhibit` | `no_shortcuts_inhibit = true` |
| `unset` | (rules are not unsettable; use handle `:set_enabled(false)`) |

**Match props** (the `class:(...)`-family):

```lua
hl.window_rule({ match = { class = "kitty" }, ... })              -- class:
hl.window_rule({ match = { title = ".*" }, ... })                 -- title:
hl.window_rule({ match = { initial_class = "..." }, ... })        -- initialclass:
hl.window_rule({ match = { initial_title = "..." }, ... })        -- initialtitle:
hl.window_rule({ match = { tag = "+foo" }, ... })                 -- tag:
hl.window_rule({ match = { workspace = "2" }, ... })              -- workspace:
hl.window_rule({ match = { float = true }, ... })                 -- floating:
hl.window_rule({ match = { xwayland = true }, ... })              -- xwayland:
hl.window_rule({ match = { fullscreen = true }, ... })            -- fullscreen:
hl.window_rule({ match = { pin = true }, ... })                   -- pinned:
hl.window_rule({ match = { group = true }, ... })                 -- grouped:
hl.window_rule({ match = { modal = true }, ... })                 -- modal:
hl.window_rule({ match = { focus = true }, ... })                 -- focus:
hl.window_rule({ match = { content = "video" }, ... })            -- content:
```

## 5.6 Layer rules

```lua
-- hyprlang:  layerrule = blur, rofi
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })

-- hyprlang:  layerrule = ignorealpha 0.5, notifications
hl.layer_rule({ match = { namespace = "notifications" }, ignore_alpha = 0.5 })

-- hyprlang:  layerrule = noanim, quickshell
hl.layer_rule({ match = { namespace = "quickshell" }, no_anim = true })
```

## 5.7 Workspace rules

```lua
-- hyprlang:  workspace = 3, gapsout:0, gapsin:0
hl.workspace_rule({ workspace = "3", gaps_out = 0, gaps_in = 0 })

-- hyprlang:  workspace = name:gaming, monitor:DP-1, default:true
hl.workspace_rule({ workspace = "name:gaming", monitor = "DP-1", default = true })

-- hyprlang:  workspace = 5, on-created-empty:firefox
hl.workspace_rule({ workspace = "5", on_created_empty = "firefox" })

-- hyprlang:  workspace = 2, layoutopt:...
hl.workspace_rule({ workspace = "2", layout_opts = { ... } })   -- layout-specific table

-- hyprlang:  workspace = special:scratchpad, on-created-empty:foot
hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "foot" })
```

## 5.8 Animations

```lua
-- hyprlang:
--   bezier = wind, 0.05, 0.9, 0.1, 1.05
--   animation = windows, 1, 7, wind, slide
hl.curve("wind", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "wind", style = "slide" })

-- hyprlang:  animation = windows, 0
hl.animation({ leaf = "windows", enabled = false })

-- springs are new:
hl.curve("my_spring", { type = "spring", mass = 1, stiffness = 70, dampening = 10 })
hl.animation({ leaf = "windows", enabled = true, speed = 10, spring = "my_spring", style = "popin" })
```

## 5.9 Environment

```lua
-- hyprlang:  env = GDK_BACKEND,wayland
hl.env("GDK_BACKEND", "wayland")

-- hyprlang:  envd = XDG_CURRENT_DESKTOP,Hyprland   (dbus)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland", true)

-- hyprlang:  env = PATH, $PATH:/custom
hl.env("PATH", os.getenv("PATH") .. ":/custom")
```

## 5.10 Autostart

```lua
-- hyprlang:  exec-once = waybar & nm-applet
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("nm-applet")
end)

-- on exit
hl.on("hyprland.shutdown", function() hl.exec_cmd("save-state.sh") end)

-- per-bind exec stays a dispatcher:
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
```

## 5.11 Config categories → `hl.config`

```lua
-- hyprlang:  general { gaps_in = 2  gaps_out = 4  border_size = 2 }
hl.config({ general = { gaps_in = 2, gaps_out = 4, border_size = 2 } })

-- hyprlang:  decoration { rounding = 10  dim_inactive = true
--                       shadow { enabled = false }  blur { size = 6  passes = 2 } }
hl.config({
    decoration = {
        rounding = 10,
        dim_inactive = true,
        shadow = { enabled = false },
        blur = { size = 6, passes = 2 },
    },
})

-- hyprlang:  input { kb_layout = us  kb_options = ctrl:nocaps
--                   touchpad { natural_scroll = false } }
hl.config({
    input = {
        kb_layout = "us",
        kb_options = "ctrl:nocaps",
        touchpad = { natural_scroll = false },
    },
})

-- hyprlang:  group { col.border_active = rgba(...)  groupbar { enabled = true } }
hl.config({
    group = {
        col = { border_active = { colors = { "rgba(7D4AB466)" }, angle = 45 } },
        groupbar = { enabled = true },
    },
})
```

## 5.12 Colors

```lua
-- hyprlang:  0xff7D4AB4  →  four Lua forms (all valid)
"#7D4AB4"                 -- web style (0.55+)
"rgb(7D4AB4)"             -- hex compact
"rgba(7D4AB4ff)"          -- with alpha
0xff7D4AB4                -- legacy ARGB int (works, but avoid)

-- gradients
col = { active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 } }
```

## 5.13 `hyprctl` CLI mapping

| old | new (0.56+) |
|---|---|
| `hyprctl keyword general:gaps_in 0` | `hyprctl eval 'hl.config({ general = { gaps_in = 0 } })'` |
| `hyprctl dispatch exec foo` | `hyprctl eval 'hl.exec_cmd("foo")'` |
| `hyprctl dispatch workspace 1` | `hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = 1 }))'` |
| socket2 event watch | `hl.on("event.name", function(...) end)` in config |
| `hyprctl reload` | still works; plus `hyprctl config full-reload` |

Next: [06-migrating-settings-and-variables.md](06-migrating-settings-and-variables.md)
