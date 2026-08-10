# Hyprland 0.55 — Lua Migration Reference

Source: [hyprwm/hyprland-wiki](https://github.com/hyprwm/hyprland-wiki) `main` branch, `content/` directory (fetched raw). Since Hyprland 0.55, **hyprlang (`.conf`) is deprecated in favor of Lua**. Config lives at `~/.config/hypr/hyprland.lua`.

All pages carry this note: *"Looking for the old hyprlang syntax? Check the [0.54 wiki pages](https://wiki.hypr.land/0.54.0/)."*

---

## Fetch status

| Page (raw path under `content/Configuring/`) | Status |
|---|---|
| Basics/Binds.md | OK |
| Basics/Monitors.md | OK |
| Basics/Window-Rules.md | OK |
| Basics/Workspace-Rules.md | OK |
| Basics/Variables.md | OK |
| Basics/Dispatchers.md | OK |
| Basics/Autostart.md | OK (replaces the requested `Execs.md`, which 404'd) |
| Advanced and Cool/Animations.md | OK |
| Advanced and Cool/Devices.md | OK |
| Advanced and Cool/Environment-variables.md | OK |
| Advanced and Cool/Expanding-functionality.md | OK |
| Advanced and Cool/Uncommon-tips-and-tricks.md | OK (replaces the requested `Suggestions-and-Tips.md`, which 404'd) |
| Basics/_index.md | OK (short intro) |
| Basics/Configuration.md | **404 — does not exist** on main |
| Basics/Execs.md | **404 — renamed to `Autostart.md`** |
| Basics/Environment-variables.md | **404 — env vars doc lives at Advanced-and-Cool/Environment-variables.md** |
| Basics/Misc.md | **404 — misc options are now a section of Variables.md (`misc.`)** |
| Basics/Keyword.md | **404 — does not exist** |
| Advanced and Cool/Decorations.md | **404 — decoration options are a section of Variables.md (`decoration.`)** |
| Advanced and Cool/Suggestions-and-Tips.md | **404 — renamed to `Uncommon-tips-and-tricks.md`** |
| Advanced and Cool/From-vanilla-to-better.md | **404 — does not exist** |
| Basics/Dont-Disable.md | **404 — does not exist** |

Full directory listing (Basics): `_index.md`, `Autostart.md`, `Binds.md`, `Dispatchers.md`, `Monitors.md`, `Variables.md`, `Window-Rules.md`, `Workspace-Rules.md`.

Full directory listing (Advanced and Cool): `_index.md`, `Animations.md`, `Devices.md`, `Environment-variables.md`, `Expanding-functionality.md`, `Gestures.md`, `Multi-GPU.md`, `Notifications.md`, `Performance.md`, `Permissions.md`, `Tearing.md`, `Uncommon-tips-and-tricks.md`, `Using-hyprctl.md`, `Virtual-GPU.md`, `XWayland.md`.

---

## 1. Core API surface (summary)

| Old hyprlang | New Lua | Section |
|---|---|---|
| `general { ... }`, `decoration { ... }`, `input { ... }`, … all `category { key = value }` blocks | `hl.config({ category = { value = ... }, ... })` | Variables |
| `$VAR` variables / `source = path` | Lua locals / Lua `dofile` / `require` (not documented explicitly — Lua semantics apply) | Variables |
| `exec-once = cmd` / `exec = cmd` | `hl.on("hyprland.start", function() hl.exec_cmd(cmd) end)` / `hl.bind(..., hl.dsp.exec_cmd(cmd))` | Autostart, Binds |
| `bind` / `bindl` / `bindr` / `bindt` / `binds` / `bindm` | `hl.bind(keys, dispatcher, { locked = true / release = true / transparent = true / repeating = true / mouse = true })` | Binds |
| `unbind` | `hl.unbind("KEYS")` | Binds |
| `monitor = ...` | `hl.monitor({ ... })` | Monitors |
| `windowrule = ...` | `hl.window_rule({ name?, match = {...}, <effects> })` | Window-Rules |
| `layerrule = ...` | `hl.layer_rule({ name?, match = {...}, <effects> })` | Window-Rules |
| `workspacerule = ...` | `hl.workspace_rule({ workspace = ..., <rules> })` (note: single table, not variadic in the doc's examples despite signature showing `(workspace, rule1, ...)`) | Workspace-Rules |
| `animations { }` + `animation = ...` + `bezier = ...` | `hl.config({ animations = {...} })` + `hl.animation({...})` + `hl.curve(NAME, {...})` | Variables, Animations |
| `env = KEY,VALUE` | `hl.env("KEY", "VALUE")` | Environment-variables |
| `device { name = ... }` | `hl.device({ name = "...", ... })` | Devices |
| `submap = ...` + `bind` inside submap | `hl.dsp.submap(name)` + `hl.define_submap(name, function() ... end)` | Binds |
| `dispatch` (hyprctl) | `hl.dispatch(hl.dsp.xxx(...))` | Dispatchers |
| `exec, cmd, rules` | `hl.dsp.exec_cmd(cmd, rules_table)` | Dispatchers |
| `/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock` events | `hl.on("event.name", function(...) ... end)` | Expanding-functionality |
| `hyprctl keyword ...` | `hl.config({...})` at runtime, `hl.get_config(...)` to read | Expanding-functionality |
| `hyprctl setprop` | `hl.dsp.window.set_prop({ prop, value, window? })` | Dispatchers |

Note: the dispatcher objects (`hl.dsp.*`) are *descriptions of actions*, not immediate invocations. They must be passed to `hl.bind()` or `hl.dispatch()`.

---

## 2. Binds (`Binds.md`)

### Basic

```lua
hl.bind(keys, dispatcher)
```

```lua
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("firefox"))
```

A Lua function can be used as the dispatcher:

```lua
hl.bind("SUPER + SHIFT + X", function()
    -- some logic...
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end)
```

> [!WARNING]
> **Keybind handlers must not block.** Lua callbacks run on the compositor event loop. Avoid `io.popen`, network I/O, clipboard tools (`wl-paste`, `xclip`), sleeps, and other long-running work inside bind functions. Prefer `hl.dsp.exec_cmd(...)` for external commands so they run outside the bind callback. If you must probe the system from Lua, bound the wait (e.g. with `timeout`). A hung or slow call freezes input and the entire desktop until it returns.

### Keycode binds

Put `code:` prefix in the KEY position: `hl.bind("SUPER + code:28", hl.dsp.exec_cmd("amongus"))` (keycode 28 = `t`). Keysym names = segment after `XKB_KEY_` in xkbcommon-keysyms.h. Use `wev` to find names/keycodes.

### Bind flags

```lua
hl.bind(keys, dispatcher, { flag1 = true, flag2 = true })
```

| Flag | Description |
|------|-------------|
| `locked` | Will also work when an input inhibitor (e.g. a lockscreen) is active. |
| `release` | Will trigger on release of a key. |
| `click` | Will trigger on release of a key or button as long as the mouse cursor stays inside `binds:drag_threshold`. |
| `drag` | Will trigger on release of a key or button as long as the mouse cursor moves outside `binds:drag_threshold`. |
| `long_press` | Will trigger on long press of a key. |
| `repeating` | Will repeat when held. |
| `non_consuming` | Key/mouse events will be passed to the active window in addition to triggering the dispatcher. |
| `auto_consuming` | Key/mouse events will be passed to the active window if the dispatcher doesn't succeed. |
| `mouse` | See the dedicated Mouse Binds section. |
| `transparent` | Cannot be shadowed by other binds. |
| `ignore_mods` | Will ignore modifiers. |
| `description` | Will allow you to write a description for your bind. |
| `dont_inhibit` | Bypasses the app's requests to inhibit keybinds. |
| `submap_universal` | Will be active no matter the submap. |
| `device` | Allow binds to be set per device. |
| `allow_input_capture` | When input is captured by a client, this bind will still be processed. |

### Mouse buttons, modkeys, wheel

- Mouse buttons: prefix keycode with `mouse:` — `hl.bind("SUPER + mouse:272", hl.dsp.exec_cmd("amongus"))`. LMB → 272, RMB → 273, MMB → 274.
- Binding a modkey only: use TARGET modmask + `release` flag, e.g. `hl.bind("ALT + ALT_L", hl.dsp.exec_cmd("amongus"), { release = true })`.
- Mouse wheel: `mouse_up`, `mouse_down`, `mouse_left`, `mouse_right` — `hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e-1" }))`. Reset time controlled by `hl.config({ binds = { scroll_event_delay = ... } })`.

### Switches

```lua
hl.bind("switch:[switch name]", hl.dsp.exec_cmd("swaylock"), { locked = true }) -- toggled
hl.bind("switch:on:[switch name]", ...)  -- turning on
hl.bind("switch:off:[switch name]", ...) -- turning off
```

`hyprctl devices` lists switches. Systemd `HandleLidSwitch` in `logind.conf` may conflict.

### Multiple binds / actions

Keybinds execute top to bottom in written order. Multiple actions per key via Lua lambda:

```lua
hl.bind("SUPER + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)
```

### Description

```lua
hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"), { description = "Open my favourite terminal" })
```

Read back with `hyprctl binds`.

### Per-Device Binds

```lua
hl.bind(keys, dispatcher(params), { device = { inclusive = true, list = { "device1", "device2" } } })
```

- `inclusive = true` (default if absent): only listed devices trigger. `false`: all except listed trigger.
- `list`: comma-separated strings (device names or device tags).
- Device names via `hyprctl devices`.

### Mouse Binds

```lua
hl.bind("ALT + mouse:272", hl.dsp.window.drag(), { mouse = true })   -- ALT + LMB: Move a window
hl.bind("ALT + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- ALT + RMB: Resize a window
```

| Name | Description |
| ---- | ----------- |
| `drag()` | moves the active window |
| `resize()` | resizes the active window |
| `resize({ keep_aspect_ratio })` | resizes the active window, overriding the window's `keep_aspect_ratio` prop temporarily |

Mouse binds behave like normal binds (any keys/mods allowed). While held, the mouse function activates.

Click vs drag via `binds.drag_threshold`:

```lua
hl.config({ binds = { drag_threshold = 10 } })
hl.bind("ALT + mouse:272", hl.dsp.window.drag(),  { mouse = true, drag = true })
hl.bind("ALT + mouse:272", hl.dsp.window.float(), { mouse = true, click = true })
```

Touchpad: keyboard keys can substitute for mouse clicks (see `SUPER + CTRL_L` / `SUPER + ALT_L` examples).

### Global Keybinds

Classic (all apps, incl. OBS/Discord/Firefox):

```lua
hl.bind("SUPER + F10", hl.dsp.pass({ window = "class:^(com\\.obsproject\\.Studio)$" }))
hl.bind("mouse:276", hl.dsp.pass({ window = "class:^(TeamSpeak 3)$" }))
hl.bind("SUPER + F10", hl.dsp.send_shortcut({ mods = "SUPER", key = "F4", window = "class:^(TeamSpeak 3)$" }))
```

`pass` passes PRESS and RELEASE itself (no need for `bindr`; push-to-talk works with one `pass`). Works flawlessly with native Wayland apps; XWayland is "a bit wonky" (passing must be a "global Xorg keybind").

DBus Global Shortcuts (preferred over `pass` when supported): run `hyprctl globalshortcuts`, then:

```lua
hl.bind("SUPER + SHIFT + A", hl.dsp.global("coolApp:myToggle"))
```

Only works with XDPH (xdg-desktop-portal-hyprland).

### Submaps

```lua
hl.bind("ALT + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))  -- "reset" returns to the global submap
end)
```

- Always provide a way out (e.g. `escape` → `submap("reset")`).
- Emergency exit: `hyprctl dispatch 'hl.dsp.submap("reset")'` (use `--instance` on a tty if needed).
- Multiple actions per bind + auto-close:

```lua
hl.define_submap("resize", function()
    hl.bind("right", function()
        hl.dispatch(hl.dsp.window.resize({ x = 10, y = 0, relative = true }))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
end)
```

- `submap_universal = true` flag: bind active in every submap.
- **Nesting**: `hl.define_submap` can nest; inner `reset` returns to global, or target a specific parent submap by name.
- **Auto-close on dispatch**: append `,<submap>` or `,reset` after a submap's name argument: `hl.define_submap("submapA", "submapB", function() ... end)` (switches to submapB after the key in the block runs) — note the doc example for the reset variant writes `hl.dsp.submap("submapB", "reset", function() ... end)` (likely a doc typo for `hl.define_submap`).
- **Catch-All**: `hl.bind("catchall", hl.dsp.submap("reset"))` — activates on any key; useful to block keys reaching the app or to exit on unknown keys.

### Switchable keyboard layouts

```lua
hl.config({ input = { kb_layout = "us,cz", kb_variant = ",qwerty", kb_options = "grp:alt_shift_toggle" } })
```

- First layout in the list is used for binds by default (e.g. `us,ua` → binds written as `"SUPER + A"`; `ua,us` → `"SUPER + Cyrillic_ef"`).
- Set `resolve_binds_by_sym = 1` globally or per-device to make binds activate when the typed *symbol* matches.
- Valid layouts/options: `/usr/share/X11/xkb/rules/base.lst` (`grep -i 'persian' ...`, `grep 'grp:.*toggle' ...`).

### Non-QWERTY layouts

Keys used in binds must be reachable without modifiers in your layout. On AZERTY, bind unmodified key names: `hl.bind(mainMod .. " + ampersand", hl.workspace(1))` instead of `" + 1"`.

### Unbind

```lua
hl.unbind("SUPER + O")   -- also: hyprctl eval 'hl.unbind("SUPER + O")'
```

**Case-sensitive**: must exactly match the bound keys string (`"SUPER + TAB"` ≠ `"SUPER + Tab"`).

### Example binds

Media (incl. locked):

```lua
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
```

Master kill-switch for binds: submap with only an exit bind.

Caps Lock remap via `kb_options` (`ctrl:nocaps`, `caps:swapescape`, …; `grep 'caps' /usr/share/X11/xkb/rules/base.lst`).

---

## 3. Monitors (`Monitors.md`)

### General

```lua
hl.monitor({
  output = "...",
  mode = "...",
  position = "...",
  scale = ...,
})
```

Example: `hl.monitor({ output = "DP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })`.

- `hyprctl monitors all` lists active + inactive.
- Position is in the virtual layout, computed from the **scaled and transformed** resolution (4K @ scale 2 sits at `1920x0`; add rotation→ `1080x0`).
- **Monitors cannot overlap** (warning otherwise).
- Scale must divide resolution cleanly, else "Invalid scale" warnings.
- Empty `output` = fallback rule when no other rule matches.
- `position` uses an inverse-Y cartesian system: negative y = higher.

### Mode special values

| Value | Meaning |
|---|---|
| `preferred` | display's preferred size + refresh rate |
| `highres` | highest supported resolution |
| `highrr` | highest supported refresh rate |
| `maxwidth` | widest supported resolution |

### Position special values

| Value | Meaning |
|---|---|
| `auto` | Hyprland decides; places new monitors to the right of existing ones (top-left corner root) |
| `auto-right/left/up/down` | relative placement by top-left corner root |
| `auto-center-right/left/up/down` | same, but from monitor center |

Direction on the first monitor does nothing (positioned at 0,0). Directions are always "from the center out"; duplicate directions keep stacking.

`auto` also works as a **scale** value (decided by PPI).

Recommended fallback rule:

```lua
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
```

Monitor descriptions: from `hyprctl monitors`, the `description:` value up to (not including) the portname, prefixed with `desc:`:

```lua
hl.monitor({ output = "desc:Chimei Innolux Corporation 0x150C", mode = "preferred", position = "auto", scale = 1.5 })
```

### Custom modelines

```lua
hl.monitor({ output = "DP-1", mode = "modeline 1071.101 3840 3848 3880 3920 2160 2263 2271 2277 +hsync -vsync", position = "0x0", scale = 1 })
```

### Disabling

```lua
hl.monitor({ output = "name", disabled = true })
```

Removes the monitor from the layout (windows/workspaces move). For screensaver-style off, use the `dpms` dispatcher.

### Custom reserved area

```lua
hl.monitor({ output = "name", reserved_area = 10 })
hl.monitor({ output = "name", reserved_area = { top = 10, bottom = 10, left = 0, right = 0 } })
```

Stacks on top of the calculated reserved area (e.g. bars). Only one such rule per monitor.

### All fields

All fields beyond `output` are optional and fall back to sensible defaults.

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| output | string | required | Output name or `desc:...` description prefix |
| mode | string | preferred | Resolution and refresh rate, e.g. `1920x1080@144` |
| position | string | auto | Position in the virtual layout, e.g. `1920x0` |
| scale | string / float | auto | Scale factor, e.g. `1.5` |
| disabled | boolean | false | Removes the monitor from the layout |
| transform | integer | 0 | Rotation/flip transform (0–7) |
| mirror | string | | Output name to mirror |
| bitdepth | integer | 8 | Bit depth (8 or 10) |
| cm | string | srgb | Color management preset |
| sdr_eotf | string | default | SDR transfer function (default, gamma22, srgb) |
| sdrbrightness | float | 1.0 | SDR brightness in HDR mode |
| sdrsaturation | float | 1.0 | SDR saturation in HDR mode |
| vrr | integer | 0 | VRR mode |
| icc | string | | Absolute path to an ICC profile |
| reserved_area | integer or table | 0 | Reserved area - integer for all sides, or table with top/right/bottom/left |
| supports_wide_color | integer | 0 | Force wide color gamut (-1 = off, 0 = auto, 1 = on) |
| supports_hdr | integer | 0 | Force HDR support (-1 = off, 0 = auto, 1 = on) |
| sdr_min_luminance | float | 0.2 | SDR minimum luminance for SDR→HDR mapping |
| sdr_max_luminance | integer | 80 | SDR maximum luminance |
| min_luminance | float | -1 | Monitor minimum luminance |
| max_luminance | integer | -1 | Monitor maximum possible luminance |
| max_avg_luminance | integer | -1 | Monitor maximum average luminance |

### Mirroring

```lua
hl.monitor({ output = "DP-3", mode = "1920x1080@60", position = "0x0", scale = 1, mirror = "DP-2" })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, mirror = "DP-1" })
```

Mirroring does not re-render; resolution follows the source. Aspect mismatch → squish/stretch.

### 10 bit

`bitdepth = 10`. Warning: Hyprland-registered colors (e.g. border color) don't support 10 bit; some apps don't support 10-bit screen capture.

### Color management presets (`cm`)

```
auto    - srgb for 8bpc, wide for 10bpc if supported (recommended)
srgb    - sRGB primaries (default)
dcip3   - DCI P3 primaries
dp3     - Apple P3 primaries
adobe   - Adobe RGB primaries
wide    - wide color gamut, BT2020 primaries
edid    - primaries from edid (known to be inaccurate)
hdr     - wide color gamut and HDR PQ transfer function (experimental)
hdredid - same as hdr with edid primaries (experimental)
```

Fullscreen HDR without `hdr` cm is possible if `render:cm_auto_hdr` is enabled. `sdrbrightness`/`sdrsaturation` control SDR in HDR mode (typical brightness `1.0 ... 2.0`). `sdr_eotf` default `"default"` follows `render.cm_sdr_eotf`; `"srgb"` = piecewise sRGB; `"gamma22"` = Gamma 2.2.

### ICC profiles

```lua
hl.monitor({ output = "eDP-1", icc = "/path/to/icc.icm" })
```

- Path must be absolute.
- Forces `sdr_eotf` to `sRGB` for that monitor.
- Overrides the CM preset.
- Incompatible with HDR gaming ("funky stuff may happen").

### VRR

Per-display `vrr` value = the mode from the Variables page (`misc.vrr`: 0 off, 1 on, 2 fullscreen only, 3 fullscreen with video/game content).

### Transform (rotation)

```
0 -> normal (no transforms)
1 -> 90 degrees
2 -> 180 degrees
3 -> 270 degrees
4 -> flipped
5 -> flipped + 90 degrees
6 -> flipped + 180 degrees
7 -> flipped + 270 degrees
```

---

## 4. Window Rules (`Window-Rules.md`)

> Rules are evaluated top to bottom — order matters! Named rules are evaluated first, then anonymous ones, and named rules take precedence over anonymous ones. The *last* matching rule wins for a given effect.

### Syntax

```lua
-- named
hl.window_rule({
  name = "apply-something",
  match = { class = "my-window" },
  border_size = 10
})
-- anonymous
hl.window_rule({ match = { class = "my-window" }, border_size = 10 })
```

- Props = fields inside `match` (determine if rule applies). Effects = what's applied.
- **All** props must match.
- One of each prop type max (e.g. `match.class` twice is invalid); at least one prop required.
- Props/effects in any order.

### Props (`match` table)

| Field | Argument | Description |
| -------------- | --------------- | --- |
| class | \[RegEx\] | Windows with `class` matching `RegEx`. |
| title | \[RegEx\] | Windows with `title` matching `RegEx`. |
| initial_class | \[RegEx\] | Windows with `initialClass` matching `RegEx`. |
| initial_title | \[RegEx\] | Windows with `initialTitle` matching `RegEx`. |
| tag | \[name\] | Windows with matching `tag`. |
| xwayland | \[bool\] | Xwayland windows. |
| float | \[bool\] | Floating windows. |
| fullscreen | \[bool\] | Fullscreen (covering or non-covering) windows. |
| pin | \[bool\] | Pinned windows. |
| focus | \[bool\] | Currently focused window. |
| group | \[bool\] | Grouped windows. |
| modal | \[bool\] | Modal windows (e.g. "Are you sure" popups) |
| fullscreen_state_client | \[int\] | Windows with matching `fullscreenstate`. `0` - none, `1` - maximize, `2` - fullscreen, `3` - maximize and fullscreen. |
| fullscreen_state_internal | \[int\] | Windows with matching `fullscreenstate`. `0` - none, `1` - maximize, `2` - fullscreen, `3` - maximize and fullscreen. |
| workspace | \[workspace\] | Windows on matching workspace. Can be `id`, `"name:string"` or a workspace selector. |
| content | \[string\] | Windows with specified content type (none, photo, video, game). |
| xdg_tag | \[RegEx\] | Match a window by its xdgTag (see `hyprctl clients`). |

Window info: `hyprctl clients` (note: `fullscreen` there = `fullscreen_state_internal`, `fullscreenClient` = `fullscreen_state_client`).

### RegEx

Uses Google's **RE2** (polynomial-time ops unsupported; see RE2 wiki for syntax). Negate with `negative:` prefix, e.g. `"negative:kitty"`.

### Static effects

Evaluated once at window open (always `initialTitle`/`initialClass` in effect). Cannot float/etc. a window based on later `title` changes — use a `hl.on("window.title", ...)` event listener + dispatch instead.

| Effect | Argument | Description |
| ---- | ----------- | --- |
| float | boolean | Floats a window. |
| tile | boolean | Tiles a window. |
| fullscreen | boolean | Fullscreens a window. |
| maximize | boolean | Maximizes a window. |
| fullscreen_state | string | Sets the fullscreen mode, e.g. `"1 2"` (internal client). Values: `0` none, `1` maximize, `2` fullscreen, `3` maximize and fullscreen. |
| move | string | Moves a floating window to a given coordinate, monitor-local. E.g. `{100, 200}` or `{"(cursor_x-(window_w*0.5))", "(cursor_y-(window_h*0.5))"}`. |
| size | string | Resizes a floating window. E.g. `{800, 600}` or `{"(monitor_w*0.5)", "(monitor_h*0.5)"}`. |
| center | boolean | If the window is floating, will center it on the monitor. |
| pseudo | boolean | Pseudotiles a window. |
| monitor | string | Sets the monitor on which a window should open. E.g. `"1"` or `"DP-1"`. Can be suffixed with `" silent"` |
| workspace | string | Sets the workspace on which a window should open. Can also be `"unset"` or suffixed with `" silent"`. |
| no_initial_focus | boolean | Disables the initial focus to the window. |
| pin | boolean | Pins the window (i.e. show it on all workspaces). *Note: pinning is ignored for non-floating windows — use with `float = true`.* |
| group | string | Sets window group properties. See group options below. |
| suppress_event | string | Ignores specific events. Space-separated: `"fullscreen"`, `"maximize"`, `"activate"`, `"activatefocus"`, `"fullscreenoutput"`, `"x11configurerequest"`. |
| content | string | Sets content type: `"none"`, `"photo"`, `"video"`, or `"game"`. |
| no_close_for | integer | Makes the window uncloseable with `killactive` for a given number of ms on open. |
| scrolling_width | number | Set column width for window when starting on a workspace with the scrolling layout. |

**Expressions** (for `move`/`size`): space-separated, no spaces inside each expression, monitor-local variables: `monitor_w`, `monitor_h`, `window_x`, `window_y`, `window_w`, `window_h`, `cursor_x`, `cursor_y`.

```lua
move = {"window_w * 0.5", "(monitor_h / 2) + 17"}
size = {"monitor_w * 0.5", "monitor_h * 0.5"}
```

### Dynamic effects

Re-evaluated every time a property changes.

| Effect | Argument | Description |
| ---- | ----------- | --- |
| persistent_size | boolean | For floating windows, internally store their size. When a new floating window opens with the same class and title, restore the saved size. |
| no_max_size | boolean | Removes max size limitations. |
| stay_focused | boolean | Forces focus on the window as long as it's visible. |
| animation | string | Forces an animation onto a window with an optional style. E.g. `"popin"` or `"popin 80%"`. |
| border_color | gradient | Force the border color. Accepts a color, gradient, or two gradients (active/inactive). E.g. `"rgb(FF0000)"` or `{ colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 }`. |
| idle_inhibit | string | Sets an idle inhibit rule. Modes: `"none"`, `"always"`, `"focus"`, `"fullscreen"`. |
| opacity | string | Additional opacity multiplier. E.g. `"0.8"` (overall), `"0.9 0.7"` (active/inactive), `"1.0 0.8 0.9"` (active/inactive/fullscreen). Append `" override"` after each value to set absolute instead of multiplied. |
| tag | string | Applies a tag. Prefix `+`/`-` to set/unset, no prefix to toggle. E.g. `"+myTag"`. |
| max_size | vec2 | Sets the maximum size for floating windows. E.g. `{ 800, 600 }`. |
| min_size | vec2 | Sets the minimum size for floating windows. E.g. `{ 200, 150 }`. |
| border_size | integer | Sets the border size. |
| rounding | integer | Forces X pixels of rounding, ignoring the default. |
| rounding_power | number | Overrides the rounding power for the window. |
| allows_input | boolean | Forces an XWayland window to receive input even if it requests not to. |
| dim_around | boolean | Dims everything around the window. Meant for floating windows. |
| decorate | boolean | Whether to draw window decorations. (default: `true`) |
| focus_on_activate | boolean | Whether Hyprland should focus an app that requests to be focused. |
| keep_aspect_ratio | boolean | Forces aspect ratio when resizing with the mouse. |
| nearest_neighbor | boolean | Forces nearest-neighbor filtering. |
| no_anim | boolean | Disables animations for the window. |
| no_blur | boolean | Disables blur for the window. |
| no_dim | boolean | Disables window dimming for the window. |
| no_focus | boolean | Disables focus to the window. |
| no_follow_mouse | boolean | Prevents the window from being focused when the mouse moves over it when `input.follow_mouse=1` is set. |
| no_shadow | boolean | Disables shadows for the window. |
| no_wobble | boolean | Disables wobble for the window. |
| no_shortcuts_inhibit | boolean | Disallows the app from inhibiting your shortcuts. |
| no_screen_share | boolean | Hides the window and its popups from screen sharing by drawing black rectangles in their place. |
| no_vrr | boolean | Disables VRR for the window. Only works when `misc.vrr` is `2` or `3`. |
| no_auto_hdr | boolean | Disables AutoHDR for the window (stops e.g. `foot` triggering AutoHDR on fullscreen). |
| opaque | boolean | Forces the window to be opaque. |
| force_rgbx | boolean | Forces Hyprland to ignore the alpha channel entirely. |
| sync_fullscreen | boolean | Whether the fullscreen mode should always be the same as the one sent to the window. |
| immediate | boolean | Forces the window to allow tearing. |
| xray | boolean | Sets blur xray mode for the window. |
| render_unfocused | boolean | Forces the window to think it's being rendered when it's not visible. |
| scroll_mouse | number | Forces the window to override `input.scroll_factor`. |
| scroll_touchpad | number | Forces the window to override `input.touchpad.scroll_factor`. |
| confine_pointer | boolean | Locks the mouse cursor to the window (e.g. gaming). |
| tonemap | string | Tonemapping behavior: `on` (Default), `off` disables tonemapping, `clamp` clamps source luminance to target, `limited` uses a dynamic curve to tonemap only the top end out of bounds content. |
| no_xdg_drags | boolean | If true, will disable XDG-driven drags for the window (e.g. dragging a CSD top bar) |

All dynamic effects can be set via `set_prop`.

### `group` window rule options

Space-separated string options:

- `"set"` \[`"always"`\] - Open window as a group.
- `"new"` - Shorthand for `"barred set"`.
- `"lock"` \[`"always"`\] - Lock the group. Combine with `"set"` or `"new"`.
- `"barred"` - Do not automatically group into the focused unlocked group.
- `"deny"` - Do not allow the window to be toggled as or added to a group.
- `"invade"` - Force open window in the locked group.
- `"override"` \[other options\] - Override other `group` rules.
- `"unset"` - Clear all `group` rules.

`group` with no options = `group = "set"`. `set`/`lock` only affect new windows once unless `always`.

### Tags

- Static tags (via `tagwindow` dispatcher) vs dynamic tags (via `tag` effect; dynamic tags have a `*` suffix in `hyprctl clients`).
- `tag` effect only manipulates **dynamic** tags; `tagwindow` dispatcher works only with **static** tags (dynamic tags are cleared when the dispatcher is called).

```bash
hyprctl dispatch 'hl.dsp.window.tag({ tag = "+code" })'
hyprctl dispatch 'hl.dsp.window.tag({ tag = "+music", window = "class:Celluloid" })'
```

```lua
hl.window_rule({ match = { class = "footclient" }, tag = "+term" })   -- Add dynamic tag `term*`
hl.window_rule({ match = { tag = "term*" },        opacity = "0.6" }) -- Match `term*` only, not bare `term`
hl.window_rule({ match = { tag = "term" },         tag = "-code" })   -- Remove dynamic tag `code*`
```

Tag matching: `tag = "code"` matches `code` or `code*`; `tag = "term*"` matches only dynamic.

### Example rules

```lua
hl.window_rule({
  name      = "move-kitty",
  match     = { class = "kitty" },
  move      = {100, 100},
  animation = "popin",
})
hl.window_rule({ match = { class = "firefox" }, no_blur = true })
hl.window_rule({
  match = { class = "kitty" },
  move  = {"cursor_x-(window_w*0.5)", "cursor_y-(window_h*0.5)"},
})
hl.window_rule({
  match        = { fullscreen = true },
  border_color = "rgb(FF0000) rgb(880808)",
})
hl.window_rule({ match = { title = ".*Hyprland.*" }, border_color = "rgb(FFFF00)" })
hl.window_rule({
  match   = { class = "kitty" },
  opacity = "1.0 override 0.5 override 0.8 override",
})
hl.window_rule({ match = { class = "kitty" }, rounding = 10 })
hl.window_rule({
  match        = { class = "(pinentry-)(.*)" },
  stay_focused = true,
})
```

### Precedence & opacity math

- Top-to-bottom; last match wins (examples with `float`/`kitty` opacity rules).
- Named rules evaluated first, then anonymous; named take precedence.
- Opacity is a **product** of all opacities (e.g. `active_opacity 0.5` × `opacity 0.5` = `0.25`). Over `1.0` → graphical glitches. `" override"` suffix makes a value absolute/exact.

### Dynamic enable/disable

`hl.window_rule()` returns a handle (only named rules can be toggled):

```lua
local myRule = hl.window_rule({ name = "my-rule", match = { class = "kitty" }, border_size = 5 })
myRule:set_enabled(false)
myRule:set_enabled(true)
myRule:is_enabled()
```

### Layer Rules

`hl.layer_rule()` — syntax same as `hl.window_rule()`.

Props:

| Field | Argument | Description |
| -------------- | --------------- | --- |
| namespace | \[RegEx\] | Namespace of the layer. Check `hyprctl layers`. |

Effects:

| Effect | Argument | Description |
| ---- | ----------- | --- |
| no_anim | boolean | Disables animations. |
| blur | boolean | Enables blur for the layer. |
| blur_popups | boolean | Enables blur for popups. |
| ignore_alpha | number | Makes blur ignore pixels with opacity of `a` or lower. Float from `0` to `1`. |
| dim_around | boolean | Dims everything behind the layer. |
| xray | boolean | Sets the blur xray mode for the layer. |
| animation | string | Sets a specific animation style for this layer. |
| order | integer | Sets the order relative to other layers. Higher `n` = closer to edge of monitor. Can be negative. |
| above_lock | integer | If non-zero, renders the layer above the lockscreen. `2` = interactive on lockscreen. |
| no_screen_share | boolean | Hides the layer from screen sharing. |

Examples:

```lua
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.5 })
-- named + handle
local selectionRule = hl.layer_rule({ name = "no-anim-for-selection", match = { namespace = "selection" }, no_anim = true })
```

---

## 5. Workspace Rules (`Workspace-Rules.md`)

### Syntax

```lua
hl.workspace_rule(workspace, rule1, rule2, ...)
```

- WORKSPACE: valid workspace identifier (see Dispatchers → Workspaces); mandatory. Can be a workspace selector, but selectors only match **existing** workspaces.
- RULES: one or more rules (in practice the doc examples use a single table form: `hl.workspace_rule({ workspace = "3", no_rounding = true, ... })`).

### Workspace selectors

Space-separated props (no spaces inside props):

- `r[A-B]` - ID range A to B inclusive
- `s[bool]` - special or not
- `n[bool]`, `n[s:string]`, `n[e:string]` - named actions: whether named, starts with, ends with
- `m[monitor]` - monitor selector
- `w[(flags)A-B]`, `w[(flags)X]` - window counts: range or specific number. Flags: `t` tiled-only, `f` floating-only, `g` count groups instead of windows, `v` visible only, `p` pinned only
- `f[-1]`, `f[0]`, `f[1]`, `f[2]` - fullscreen state: `-1` no FS, `0` fullscreen, `1` maximized, `2` fullscreen without state sent to window (only matches workspaces with covering FS windows)

### Rules table

| Rule | Description | type |
| --- | --- | --- |
| monitor | Binds a workspace to a monitor. | string |
| default | Whether this workspace should be the default workspace for the given monitor | bool |
| gaps_in | Set the gaps between windows (equiv. `general.gaps_in`) | css_gaps |
| gaps_out | Set the gaps between windows and monitor edges (equiv. `general.gaps_out`) | css_gaps |
| float_gaps | Gaps for floating windows (equiv. `general.float_gaps`) | css_gaps |
| border_size | Border size around windows (equiv. `general.border_size`) | int |
| no_border | Whether to disable borders | bool |
| no_shadow | Whether to disable shadows | bool |
| no_wobble | Whether to disable wobble | bool |
| no_rounding | Whether to disable rounded windows | bool |
| decorate | Whether to draw window decorations or not | bool |
| persistent | Keep this workspace alive even if empty and inactive | bool |
| on_created_empty | A command to be executed once a workspace is created empty (i.e. not created by moving a window to it). See the command syntax (Dispatchers → Executing with rules) | string |
| default_name | A default name for the workspace. | string |
| layout | The layout to use for this workspace. | string |
| animation | The animation style to use for this workspace. | string |
| layout_opts | A table of layout-specific options for this workspace. Keys and values depend on the layout. | table |

### Examples

```lua
hl.workspace_rule({ workspace = "3", no_rounding = true, decorate = false })
hl.workspace_rule({ workspace = "name:coding", no_rounding = true, decorate = false, gaps_in = 0, gaps_out = 0, no_border = true, monitor = "DP-1" })
hl.workspace_rule({ workspace = "8", border_size = 8 })
hl.workspace_rule({ workspace = "name:Hello", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "name:gaming", monitor = "desc:Chimei Innolux Corporation 0x150C", default = true })
hl.workspace_rule({ workspace = "5", on_created_empty = "[float] firefox" })
hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "foot" })
hl.workspace_rule({ workspace = "15", animation = "slidevert", default_name = "slider" })
```

### Smart gaps

```lua
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, rounding = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]" }, rounding = 0 })
```

Ignoring special workspaces: append `s[false]` to selectors (see full example in source).

### Per-workspace layouts

```lua
hl.workspace_rule({ workspace = "2", layout = "scrolling" })
```

---

## 6. Variables / Options (`Variables.md`)

### Syntax

```lua
hl.config({
   category = { value = ... },
   category2 = { value2 = ... }
})
```

Multiple `hl.config()` invocations allowed; each updates only what's passed. Callable at runtime.

### Variable types

| type | description |
| --- | --- |
| int | integer |
| bool | boolean (`true` or `false`) |
| float | floating point number |
| color | color (see below) |
| vec2 | vector with 2 float values (e.g. `{ 20, 20 }`) |
| str | a string (wrapped into "", e.g: `"dwindle"`) |
| gradient | a gradient, will accept a color, or `{ colors = { "rgba(...)", "rgba(...)" }, angle? = 45 }` |
| font_weight | an integer between 100 and 1000, or a preset: `"thin"` `"ultralight"` `"light"` `"semilight"` `"book"` `"normal"` `"medium"` `"semibold"` `"bold"` `"ultrabold"` `"heavy"` `"ultraheavy"` |
| css_gaps | an integer, or `{ top?, left?, right?, bottom? }` |

**Colors** — 4 representations:
- web-styled hash: `"#fafc21"` / `"#ddd"` / `"#fa3d7bff"` (rgba order)
- `"rgba(b3ff1aee)"` or decimal `"rgba(179,255,26,0.933)"` (no spaces between decimals)
- `"rgb(b3ff1a)"` or decimal `"rgb(179,255,26)"`
- legacy `0xeeb3ff1a` (ARGB order)

### General (`general.`)

| name | description | type | default |
|---|---|---|---|
| border_size | size of the border around windows | int | `1` |
| gaps_in | gaps between windows | css_gaps | `5` |
| gaps_out | gaps between windows and monitor edges | css_gaps | `20` |
| float_gaps | gaps between windows and monitor edges for floating windows `-1` means default | css_gaps | `0` |
| gaps_workspaces | gaps between workspaces. Stacks with gaps_out. | int | `0` |
| col.inactive_border | border color for inactive windows | gradient | `0xff444444` |
| col.active_border | border color for the active window | gradient | `0xffffffff` |
| col.nogroup_border | inactive border color for window that cannot be added to a group | gradient | `0xffffaaff` |
| col.nogroup_border_active | active border color for window that cannot be added to a group | gradient | `0xffff00ff` |
| layout | which layout: `"dwindle"`/`"master"`/`"scrolling"`/`"monocle"` | str | `"dwindle"` |
| no_focus_fallback | if true, will not fall back to the next available window when moving focus in a direction where no window was found | bool | `false` |
| resize_on_border | enables resizing windows by clicking and dragging on borders and gaps | bool | `false` |
| extend_border_grab_area | extends the area around the border where you can click and drag on, only used when `general.resize_on_border` is on. | int | `15` |
| hover_icon_on_border | show a cursor icon when hovering over borders, only used when `general.resize_on_border` is on. | bool | `true` |
| allow_tearing | master switch for allowing tearing to occur | bool | `false` |
| resize_corner | force floating windows to use a specific corner when being resized (1-4 clockwise from top left, 0 to disable) | int | `0` |
| modal_parent_blocking | whether parent windows of modals will be interactive | bool | `true` |
| locale | overrides the system locale (e.g. `"en_US"`, `"es"`) | str | \[\[Empty\]\] |

#### Snap (`general.snap.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | enable snapping for floating windows | bool | `false` |
| window_gap | minimum gap in pixels between windows before snapping | int | `10` |
| monitor_gap | minimum gap in pixels between window and monitor edges before snapping | int | `10` |
| border_overlap | if true, windows snap such that only one border's worth of space is between them | bool | `false` |
| respect_gaps | if true, snapping will respect gaps between windows (general.gaps_in) | bool | `false` |

### Decoration (`decoration.`)

| name | description | type | default |
| --- | --- | --- | --- |
| rounding | rounded corners' radius (in layout px) | int | `0` |
| rounding_power | curve used for rounding corners, larger is smoother, 2.0 circle, 4.0 squircle. [2.0 - 10.0] | float | `2.0` |
| active_opacity | opacity of active windows. [0.0 - 1.0] | float | `1.0` |
| inactive_opacity | opacity of inactive windows. [0.0 - 1.0] | float | `1.0` |
| fullscreen_opacity | opacity of fullscreen windows. [0.0 - 1.0] | float | `1.0` |
| dim_modal | enables dimming of parents of modal windows | bool | `true` |
| dim_inactive | enables dimming of inactive windows | bool | `false` |
| dim_strength | how much inactive windows should be dimmed [0.0 - 1.0] | float | `0.5` |
| dim_special | how much to dim the rest of the screen by when a special workspace is open. [0.0 - 1.0] | float | `0.2` |
| dim_around | how much the `dim_around` window rule should dim by. [0.0 - 1.0] | float | `0.4` |
| screen_shader | a path to a custom shader applied at the end of rendering (see `examples/screenShader.frag`) | str | \[\[Empty\]\] |
| border_part_of_window | whether the window border should be a part of the window | bool | `true` |

#### Blur (`decoration.blur.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | enable kawase window background blur | bool | `true` |
| size | blur size (distance) | int | `8` |
| passes | the amount of passes to perform | int | `1` |
| ignore_opacity | make the blur layer ignore the opacity of the window | bool | `true` |
| new_optimizations | further optimizations to the blur. Recommended to leave on. | bool | `true` |
| xray | if enabled, floating windows will ignore tiled windows in their blur. Only if new_optimizations is true. | bool | `false` |
| noise | how much noise to apply. [0.0 - 1.0] | float | `0.0117` |
| contrast | contrast modulation for blur. [0.0 - 2.0] | float | `0.8916` |
| brightness | brightness modulation for blur. [0.0 - 2.0] | float | `1.0` |
| vibrancy | Increase saturation of blurred colors. [0.0 - 1.0] | float | `0.1696` |
| vibrancy_darkness | How strong the effect of `vibrancy` is on dark areas. [0.0 - 1.0] | float | `0.0` |
| special | whether to blur behind the special workspace (note: expensive) | bool | `false` |
| popups | whether to blur popups (e.g. right-click menus) | bool | `false` |
| popups_ignorealpha | if pixel opacity is below set value, will not blur. [0.0 - 1.0] | float | `0.2` |
| input_methods | whether to blur input methods (e.g. fcitx5) | bool | `false` |
| input_methods_ignorealpha | if pixel opacity is below set value, will not blur. [0.0 - 1.0] | float | `0.2` |

`blur.size` and `blur.passes` must be ≥ 1.

#### Shadow (`decoration.shadow.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | enable drop shadows on windows | bool | `true` |
| range | Shadow range ("size") in layout px | int | `4` |
| render_power | power to render the falloff (more = faster falloff) [1 - 4] | int | `3` |
| sharp | if enabled, shadows are sharp, akin to infinite render power | bool | `false` |
| color | shadow's color. Alpha dictates opacity. | gradient | `0xee1a1a1a` |
| color_inactive | inactive shadow color (falls back to color) | gradient | unset |
| offset | shadow's rendering offset. | vec2 | `{0, 0}` |
| scale | shadow's scale. [0.0 - 1.0] | float | `1.0` |

#### Glow (`decoration.glow.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | enable inner glow on windows | bool | `false` |
| range | Glow range ("size") in layout px | int | `10` |
| render_power | falloff power [1 - 4] | int | `3` |
| color | glow's color. Alpha dictates opacity. | gradient | `0xee33ccff` |
| color_inactive | inactive glow color (falls back to color) | gradient | unset |

#### Motion blur (`decoration.motion_blur.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | enable motion blur on moving / resizing windows | bool | `false` |
| samples | The amount of samples to render. More = clearer blur, more compute. | int | `7` |

#### Wobble (`decoration.wobble.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | enable wobble on moving / resizing windows | bool | `false` |
| mesh | amount of wobble mesh vertices per edge | int | `12` |
| stiffness | spring stiffness for wobble deformation | float | `200` |
| damping | spring damping for wobble deformation | float | `12` |
| mass | spring mass for wobble deformation | float | `1` |
| intensity | wobble deformation impulse multiplier | float | `0.2` |
| value_epsilon | position epsilon below which wobble is considered stable | float | `0.25` |
| velocity_epsilon | velocity epsilon below which wobble is considered stable | float | `2` |

### Animations (`animations.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | enable animations | bool | `true` |
| workspace_wraparound | workspace wraparound, directional workspace animations animate as if first/last workspaces adjacent | bool | `false` |

### Input (`input.`)

| name | description | type | default |
|---|---|---|---|
| kb_model | Appropriate XKB keymap parameter | str | \[\[Empty\]\] |
| kb_layout | Appropriate XKB keymap parameter | str | `"us"` |
| kb_variant | Appropriate XKB keymap parameter | str | \[\[Empty\]\] |
| kb_options | Appropriate XKB keymap parameter | str | \[\[Empty\]\] |
| kb_rules | Appropriate XKB keymap parameter | str | \[\[Empty\]\] |
| kb_file | path to your custom .xkb file | str | \[\[Empty\]\] |
| numlock_by_default | Engage numlock by default. | bool | `false` |
| resolve_binds_by_sym | keybinds act as if first layout is active (false) or by symbol with current layout (true) | bool | `false` |
| repeat_rate | repeat rate for held-down keys, in repeats per second. | int | `25` |
| repeat_delay | Delay before a held-down key is repeated, in milliseconds. | int | `600` |
| sensitivity | mouse input sensitivity, clamped [-1.0, 1.0] | float | `0.0` |
| accel_profile | `"adaptive"`, `"flat"`, or `"custom"` (see below). Empty = libinput default | str | \[\[Empty\]\] |
| force_no_accel | Force no cursor acceleration. **Not recommended** (cursor desync). | bool | `false` |
| rotation | rotation of a device in degrees clockwise, clamped [0, 359] | int | `0` |
| left_handed | Switches RMB and LMB | bool | `false` |
| scroll_points | scroll acceleration profile when `accel_profile = "custom"`, form `"<step> <points>"` | str | \[\[Empty\]\] |
| scroll_method | `"2fg"`, `"edge"`, `"on_button_down"`, `"no_scroll"` | str | \[\[Empty\]\] |
| scroll_button | scroll button. Must be an int, cannot be a string. 0 = default. | int | `0` |
| scroll_button_lock | button does not need to be held; press toggles lock | bool | `false` |
| scroll_factor | Multiplier added to scroll movement for external mice | float | `1.0` |
| natural_scroll | Inverts scrolling direction | bool | `false` |
| follow_mouse | `0` no focus change, `1` always focus under cursor, `2` cursor focus detached from keyboard focus (click moves keyboard focus), `3` cursor focus completely separate | int | `1` |
| follow_mouse_shrink | shrinks inactive window hitboxes by N px (dead zone in gaps); only with follow_mouse = 1 | int | `0` |
| follow_mouse_threshold | min distance in logical px the mouse needs to travel for focus; only with follow_mouse = 1 | float | `0.0` |
| focus_on_close | `0` shift to next candidate, `1` shift to window under cursor, `2` shift to most recently used | int | `0` |
| mouse_refocus | if disabled, mouse focus won't switch unless crossing a window boundary with follow_mouse=1 | bool | `true` |
| float_switch_override_focus | 1 or 2: focus changes under cursor when switching tiled↔floating; 2 also follows on float-to-float | int | `1` |
| special_fallthrough | only floating windows in special workspace won't block focusing regular workspace | bool | `false` |
| off_window_axis_events | axis events around a focused window: `0` ignore, `1` out-of-bound coords, `2` fake closest point, `3` warp to closest point | int | `1` |
| emulate_discrete_scroll | `0` disabled, `1` non-standard events only, `2` force all scroll wheel events handled | int | `1` |

`accel_profile = "custom"`: value `custom <step> <points...>` e.g. `custom 200 0.0 0.5`. `scroll_points` (only with custom accel): `<step> <points...>` e.g. `0.2 0.0 0.5 1 1.2 1.5`.

#### Touchpad (`input.touchpad.`)

| name | description | type | default |
| --- | --- | --- | --- |
| disable_while_typing | Disable the touchpad while typing. | bool | `true` |
| natural_scroll | Inverts scrolling direction | bool | `false` |
| scroll_factor | Multiplier applied to the amount of scroll movement. | float | `1.0` |
| middle_button_emulation | LMB+RMB simultaneously = middle click | bool | `false` |
| tap_button_map | `"lrm"` (default) or `"lmr"` | str | \[\[Empty\]\] |
| clickfinger_behavior | 1/2/3 fingers → LMB/RMB/MMB | bool | `false` |
| tap_to_click | 1/2/3 finger taps → LMB/RMB/MMB | bool | `true` |
| drag_lock | `0` disabled, `1` enabled with timeout, `2` enabled sticky | int | `0` |
| tap_and_drag | tap and drag mode | bool | `true` |
| flip_x | inverts horizontal movement | bool | `false` |
| flip_y | inverts vertical movement | bool | `false` |
| drag_3fg | `0` disabled, `1` 3 fingers, `2` 4 fingers | int | `0` |

#### Touchdevice (`input.touchdevice.`)

| name | description | type | default |
| --- | --- | --- | --- |
| transform | same transforms as monitor rotation | int | `0` |
| output | monitor to bind touch devices; empty string stops auto-detection | string | \[\[Auto\]\] |
| enabled | whether input is enabled for touch devices | bool | `true` |

#### Virtualkeyboard (`input.virtualkeyboard.`)

| name | description | type | default |
| --- | --- | --- | --- |
| share_states | `0` no, `1` yes, `2` yes unless IME client | int | `2` |
| release_pressed_on_close | release all pressed keys on close | bool | `false` |

#### Tablet (`input.tablet.`)

| name | description | type | default |
| --- | --- | --- | --- |
| transform | same transforms as monitor rotation | int | `0` |
| output | monitor to bind tablets: `"current"`, a monitor name, or empty for all | string | \[\[Empty\]\] |
| region_position | position of the mapped region in monitor layout relative to top-left of bound monitor/all monitors | vec2 | `{0, 0}` |
| absolute_region_position | treat `region_position` as absolute in monitor layout (only when `output` empty) | bool | `false` |
| region_size | size of the mapped region; `{0, 0}`/invalid = unset | vec2 | `{0, 0}` |
| relative_input | whether the input should be relative | bool | `false` |
| left_handed | if enabled, the tablet will be rotated 180 degrees | bool | `false` |
| active_area_size | size of tablet's active area in mm | vec2 | `{0, 0}` |
| active_area_position | position of the active area in mm | vec2 | `{0, 0}` |

#### Tablettool (`input.tablettool.`)

| name | description | type | default |
| --- | --- | --- | --- |
| eraser_button_mode | `0` default hardware behavior, `1` eraser button sends a button event | int | 0 |
| eraser_button_override | button for eraser_button_mode=1. Must be valid button (e.g. BTN_STYLUS), not fake buttons (BTN_TOOL_*) or keys (KEY_*). `0` = default | int | 0 |
| pressure_range_min | min pressure range; negative = default (usually `0.0`) | float | -1.0 |
| pressure_range_max | max pressure range; negative = default (usually `1.0`) | float | -1.0 |

### Gestures (`gestures.`)

| name | description | type | default |
| --- | --- | --- | --- |
| workspace_swipe_distance | in px, the distance of the touchpad gesture | int | `300` |
| workspace_swipe_touch | enable workspace swiping from the edge of a touchscreen | bool | `false` |
| workspace_swipe_invert | invert the direction (touchpad only) | bool | `true` |
| workspace_swipe_touch_invert | invert the direction (touchscreen only) | bool | `false` |
| workspace_swipe_min_speed_to_force | min speed in px per timepoint to force the change ignoring `cancel_ratio`. `0` disables. | int | `30` |
| workspace_swipe_cancel_ratio | how much the swipe has to proceed to commence. [0.0 - 1.0] | float | `0.5` |
| workspace_swipe_create_new | whether a swipe right on the last workspace should create a new one | bool | `true` |
| workspace_swipe_direction_lock | switching direction locked past `direction_lock_threshold` (touchpad only) | bool | `true` |
| workspace_swipe_direction_lock_threshold | in px, distance before direction lock activates (touchpad only) | int | `10` |
| workspace_swipe_forever | swiping will not clamp at neighboring workspaces | bool | `false` |
| workspace_swipe_use_r | swiping will use the `r` prefix instead of `m` for finding workspaces | bool | `false` |
| close_max_timeout | timeout for a window to close when using a 1:1 gesture, in ms | int | `1000` |

#### Scrolling (`gestures.scrolling.`)

| name | description | type | default |
| --- | --- | --- | --- |
| move_snap_to_grid | whether scroll move gesture should snap to grid on release | bool | `true` |
| move_snap_cursor | whether it should snap the cursor to the newly focused window | bool | `true` |

> **Migration gotcha**: `workspace_swipe`, `workspace_swipe_fingers` and `workspace_swipe_min_fingers` were **removed** in favor of the new gestures system. Replicate 3-finger swipe:
> ```lua
> hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
> ```

### Group (`group.`)

| name | description | type | default |
| --- | --- | --- | --- |
| auto_group | new windows auto-grouped into focused unlocked group (per-window override: `group barred` rule) | bool | `true` |
| insert_after_current | new windows in a group spawn after current or at group tail | bool | `true` |
| focus_removed_window | focus the window just moved out of the group | bool | `true` |
| drag_into_group | `0` disabled, `1` enabled, `2` only when dragging into the groupbar | int | `1` |
| merge_groups_on_drag | window groups can be dragged into other groups | bool | `true` |
| merge_groups_on_groupbar | one group merged into another when dragged into its groupbar (only works with `drag_into_group = 2` + `merge_groups_on_drag = true`) | bool | `true` |
| merge_floated_into_tiled_on_groupbar | dragging a floating window into a tiled groupbar merges them | bool | `false` |
| group_on_movetoworkspace | movetoworkspace[silent] merges the window into the workspace's solitary unlocked group | bool | `false` |
| col.border_active | active group border color | gradient | `0x66ffff00` |
| col.border_inactive | inactive (out of focus) group border color | gradient | `0x66777700` |
| col.border_locked_active | active locked group border color | gradient | `0x66ff5500` |
| col.border_locked_inactive | inactive locked group border color | gradient | `0x66775500` |

#### Groupbar (`group.groupbar.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | enables groupbars | bool | `true` |
| disable_when_only | disable if contains single window (only if enabled == true) | bool | `false` |
| font_family | font for groupbar titles; uses `misc.font_family` if not specified | string | \[\[Empty\]\] |
| font_size | font size of groupbar title | int | `8` |
| font_weight_active | font weight of active groupbar title | font_weight | `"normal"` |
| font_weight_inactive | font weight of inactive groupbar title | font_weight | `"normal"` |
| gradients | enables gradients | bool | `false` |
| height | height of the groupbar | int | `14` |
| indicator_gap | height of gap between groupbar indicator and title | int | `0` |
| indicator_height | height of the groupbar indicator | int | `3` |
| stacked | render the groupbar as a vertical stack | bool | `false` |
| priority | decoration priority for groupbars | int | `3` |
| render_titles | whether to render titles in the group bar decoration | bool | `true` |
| text_offset | adjust vertical position for titles | int | `0` |
| text_padding | set horizontal padding for titles | int | `0` |
| scrolling | whether scrolling in the groupbar changes group active window | bool | `true` |
| rounding | how much to round the indicator | int | `1` |
| rounding_power | rounding curve for groupbar corners, 2.0 circle, 4.0 squircle [2.0 - 10.0] | float | `2.0` |
| gradient_rounding | how much to round the gradients | int | `2` |
| gradient_rounding_power | rounding curve for gradient corners [2.0 - 10.0] | float | `2.0` |
| round_only_edges | round only the indicator edges of the entire groupbar | bool | `true` |
| gradient_round_only_edges | round only the gradient edges of the entire groupbar | bool | `true` |
| text_color | color for window titles in the groupbar | color | `0xffffffff` |
| text_color_inactive | inactive titles' color (defaults to text_color) | color | unset |
| text_color_locked_active | active title in a locked group (defaults to text_color) | color | unset |
| text_color_locked_inactive | inactive titles in locked groups (defaults to text_color_inactive) | color | unset |
| col.active | active group bar background color | gradient | `0x66ffff00` |
| col.inactive | inactive group bar background color | gradient | `0x66777700` |
| col.locked_active | active locked group bar background color | gradient | `0x66ff5500` |
| col.locked_inactive | inactive locked group bar background color | gradient | `0x66775500` |
| gaps_in | gap size between gradients | int | `2` |
| gaps_out | gap size between gradients and window | int | `2` |
| keep_upper_gap | add or remove upper gap | bool | `true` |
| middle_click_close | middle clicking the groupbar closes the clicked window | bool | `true` |
| blur | applies blur to the groupbar indicators and gradients | bool | `false` |

### Misc (`misc.`)

| name | description | type | default |
|---|---|---|---|
| disable_hyprland_logo | disables the random Hyprland logo / anime girl background | bool | `false` |
| disable_splash_rendering | disables the Hyprland splash rendering (requires monitor reload) | bool | `false` |
| disable_scale_notification | disables notification popup when a monitor fails to set a suitable scale | bool | `false` |
| col.splash | Changes the color of the splash text (requires monitor reload) | color | `0x55ffffff` |
| font_family | global default font (debug fps, notifications, config errors, etc.) | string | `"Sans"` |
| splash_font_family | font for splash text (requires monitor reload) | string | \[\[Empty\]\] |
| force_default_wallpaper | any of the 3 default wallpapers; `0`/`1` disable anime background; `-1` random [-1/0/1/2] | int | `-1` |
| vrr | VRR (Adaptive Sync): 0 off, 1 on, 2 fullscreen only, 3 fullscreen with `video`/`game` content type [0/1/2/3] | int | `0` |
| mouse_move_enables_dpms | wake monitors on mouse move if DPMS off | bool | `false` |
| key_press_enables_dpms | wake monitors on key press if DPMS off | bool | `false` |
| name_vk_after_proc | name virtual keyboards after creating processes (e.g. hl-virtual-keyboard-fcitx5) | bool | `true` |
| always_follow_on_dnd | mouse focus follows mouse when drag and dropping | bool | `true` |
| layers_hog_keyboard_focus | keyboard-interactive layers keep focus on mouse move (wofi, bemenu) | bool | `true` |
| animate_manual_resizes | animate manual window resizes/moves | bool | `false` |
| animate_mouse_windowdragging | animate windows dragged by mouse (weird on some curves) | bool | `false` |
| disable_autoreload | config won't reload automatically on save; needs `hyprctl reload` | bool | `false` |
| enable_swallow | Enable window swallowing | bool | `false` |
| swallow_regex | _class_ regex for windows that should be swallowed (usually a terminal) | str | \[\[Empty\]\] |
| swallow_exception_regex | _title_ regex for windows that should _not_ be swallowed; matched against parent window's title | str | \[\[Empty\]\] |
| focus_on_activate | focus an app that requests to be focused (an `activate` request) | bool | `false` |
| mouse_move_focuses_monitor | mouse moving into a different monitor should focus it | bool | `true` |
| allow_session_lock_restore | allow restarting a lockscreen app in case it crashes | bool | `false` |
| session_lock_xray | keep rendering workspaces below your lockscreen | bool | `false` |
| session_lock_blur | Enables blur for lockscreen (`session_lock_xray` must be enabled) | bool | `false` |
| background_color | change the background color (requires `disable_hyprland_logo`) | color | `0x111111` |
| close_special_on_empty | close the special workspace if the last window is removed | bool | `true` |
| on_focus_under_fullscreen | tiled window focus request with a fullscreen window: 0 ignore, 1 takes over, 2 unfullscreen/unmaximize [0/1/2] | int | `2` |
| exit_window_retains_fullscreen | closing a fullscreen window makes the next focused window fullscreen | bool | `false` |
| initial_workspace_tracking | windows open on the workspace they were invoked on: 0 disabled, 1 single-shot, 2 persistent (all children) | int | `1` |
| initial_workspace_token_timeout | seconds a window has to open on its invoked workspace before the token expires | int | `10` |
| middle_click_paste | enable middle-click-paste (aka primary selection) | bool | `true` |
| render_unfocused_fps | max limit for render_unfocused windows' fps in the background | int | `15` |
| disable_xdg_env_checks | disable the warning if XDG environment is externally managed | bool | `false` |
| disable_hyprland_guiutils_check | disable the warning if hyprland-guiutils is not installed | bool | `false` |
| lockdead_screen_delay | delay after which the "lockdead" screen appears if a lockscreen fails to cover all outputs (5 s max) | int | `1000` |
| enable_anr_dialog | enable the ANR (app not responding) dialog | bool | `true` |
| anr_missed_pings | number of missed pings before showing the ANR dialog | int | `5` |
| size_limits_tiled | apply min_size and max_size rules to tiled windows | bool | `false` |
| screencopy_force_8b | forces 8 bit screencopy | bool | `true` |
| disable_watchdog_warning | disable the warning about not using start-hyprland | bool | `false` |
| bell_sound | path to custom wav/ogg system bell; `"none"`/empty mutes; `"default"` uses system's | str | `"default"` |
| float_force_onscreen | floating windows stay onscreen: 0 none, 1 partially, 2 fully [0/1/2] | int | `0` |
| new_float_force_onscreen | same, for newly-spawned floating windows [0/1/2] | int | `2` |

### Layout (`layout.`)

| name | description | type | default |
|---|---|---|---|
| single_window_aspect_ratio | padding so a single window conforms to the aspect ratio (e.g. `4 3` on 16:9) | Vec2D | `{0, 0}` |
| single_window_aspect_ratio_tolerance | tolerance; if padding < fraction of height/width, don't adjust [0 - 1] | int | `0.1` |

### Binds (`binds.`)

| name | description | type | default |
| --- | --- | --- | --- |
| pass_mouse_when_bound | if disabled, mouse events not passed to apps if a keybind was triggered | bool | `false` |
| scroll_event_delay | in ms, delay to allow another scroll bind after a scroll event | int | `300` |
| workspace_back_and_forth | switching to the currently focused workspace switches to the previous (i3 auto_back_and_forth) | bool | `false` |
| hide_special_on_workspace_change | changing active workspace hides the special workspace on that monitor | bool | `false` |
| allow_workspace_cycles | workspaces don't forget their previous workspace, enabling cycles | bool | `false` |
| workspace_center_on | center cursor on workspace (0) or last active window for that workspace (1) | int | `1` |
| focus_preferred_method | `hl.dsp.focus({direction})` etc: 0 history (recent priority), 1 length (longer shared edges priority) | int | `0` |
| ignore_group_lock | group-aware move dispatchers ignore lock per group | bool | `false` |
| movefocus_cycles_fullscreen | on fullscreen, `hl.dsp.focus({direction})` cycles fullscreen | bool | `false` |
| movefocus_cycles_groupfirst | in grouped windows, direction focus cycles group windows first | bool | `false` |
| window_direction_monitor_fallback | moving window/focus over a monitor edge moves to the next monitor in that direction | bool | `true` |
| disable_keybind_grabbing | apps that request keybind disabling (e.g. VMs) cannot | bool | `false` |
| allow_pin_fullscreen | allow fullscreen to pinned windows, restore pinned status afterwards | bool | `false` |
| drag_threshold | movement threshold in px for window dragging and c/g bind flags; 0 disables and grabs on mousedown | int | `0` |
| drag_center_window | dragging a tiled/fullscreen window centers it on the cursor when it becomes floating | bool | `true` |

### XWayland (`xwayland.`)

| name | description | type | default |
| --- | --- | --- | --- |
| enabled | allow running applications using X11 | bool | `true` |
| use_nearest_neighbor | nearest neighbor filtering for xwayland apps (pixelated rather than blurry) | bool | `true` |
| force_zero_scaling | forces a scale of 1 on xwayland windows on scaled displays | bool | `false` |
| create_abstract_socket | Create the abstract Unix domain socket for XWayland (restart required; Linux only) | bool | `false` |

### OpenGL (`opengl.`)

| name | description | type | default |
| --- | --- | --- | --- |
| nvidia_anti_flicker | reduces flickering on nvidia at cost of frame drops on lower-end GPUs; ignored on non-nvidia | bool | `true` |

### Render (`render.`)

| name | description | type | default |
| --- | --- | --- | --- |
| direct_scanout | reduce lag with one fullscreen app: 0 off, 1 on, 2 auto (on with content type 'game') | int | `0` |
| expand_undersized_textures | expand undersized textures along the edge rather than stretch the whole texture | bool | `true` |
| xp_mode | Disables back buffer and bottom layer rendering | bool | `false` |
| ctm_animation | fade animation for CTM changes (hyprsunset). 2 = auto (disabled on Nvidia) | int | `2` |
| cm_enabled | color management pipeline (requires restart to fully take effect) | bool | `true` |
| send_content_type | report content type to allow monitor profile autoswitch (may black-screen during switch) | bool | `true` |
| cm_auto_hdr | Auto-switch to HDR in fullscreen: 0 off, 1 switch to `cm, hdr`, 2 switch to `cm, hdredid` | int | `1` |
| new_render_scheduling | automatically uses triple buffering when needed | bool | `false` |
| non_shader_cm | CM without shader: 0 disable, 1 whenever possible, 2 DS and passthrough only, 3 disable and ignore CM issues | int | `3` |
| non_shader_cm_interop | 0 external ctm disabled in fullscreen, 1 enabled in fullscreen, 2 disabled for fullscreen photo/video/game | int | `2` |
| cm_sdr_eotf | default SDR transfer function: `"default"` (sRGB), `"gamma22"`, `"gamma22force"`, `"srgb"` | str | `"default"` |
| commit_timing_enabled | Enable commit timing proto (requires restart) | bool | `true` |
| use_fp16 | FP16 buffers internally: 0 disabled, 1 enabled, 2 enabled in hdr mode | int | `2` |
| keep_unmodified_copy | unmodified SDR frame copy for screensharing: 0 disabled, 1 on, 2 auto. Set 1 if screenshots transparent | int | `2` |
| use_shader_blur_blend | experimental blurred bg blending (glitched on rotated screens); set true if blur missing with fp16/keep_unmodified_copy | bool | `false` |
| icc_vcgt_enabled | send VCGT ramps to KMS with ICC profiles | bool | `true` |
| fp16_sdr_tf | internal workbuffer transfer function for fp16 in SDR: 0 monitor, 1 linear | int | `0` |
| not_shown_fifo_lock | fifo locking for not shown surfaces: always / ignore_unfocused / never | int | `0` |

`cm_auto_hdr` requires `--target-colorspace-hint-mode=source` mpv option with mpv > v0.40.0.

### Cursor (`cursor.`)

| name | description | type | default |
| --- | --- | --- | --- |
| invisible | don't render cursors | bool | `false` |
| sync_gsettings_theme | sync xcursor theme with gsettings (cursor-theme, cursor-size) | bool | `true` |
| no_hardware_cursors | 0 use hw cursors if possible, 1 don't, 2 auto (disable when tearing) | int | `2` |
| no_break_fs_vrr | avoid frame spikes on cursor movement for fullscreen VRR: 0 off, 1 on, 2 auto (on with 'game') | int | `2` |
| min_refresh_rate | min refresh rate for cursor movement when `no_break_fs_vrr` active | int | `24` |
| hotspot_padding | padding in logical px between screen edges and the cursor | int | `0` |
| inactive_timeout | seconds of inactivity to hide cursor; `0` = never | float | `0` |
| no_warps | will not warp the cursor in many cases (focusing, keybinds, etc.) | bool | `false` |
| persistent_warps | on refocus, cursor returns to last position relative to that window | bool | `false` |
| warp_on_change_workspace | move cursor to last focused window after workspace change: 0/1/2 (Force ignores no_warps) | int | `0` |
| warp_on_toggle_special | move cursor to last focused window on special toggle: 0/1/2 | int | `0` |
| default_monitor | default monitor for the cursor on startup | str | \[\[Empty\]\] |
| zoom_factor | zoom factor around cursor, minimum 1.0 (no zoom) | float | `1.0` |
| zoom_rigid | zoom follows cursor rigidly (cursor centered) or loosely | bool | `false` |
| zoom_detached_camera | camera detached from mouse when zoomed, only moving to keep mouse in view | bool | `true` |
| enable_hyprcursor | whether to enable hyprcursor support | bool | `true` |
| hide_on_key_press | hide cursor on any key press until mouse moves | bool | `false` |
| hide_on_touch | hide cursor after touch input until mouse input | bool | `true` |
| hide_on_tablet | hide cursor after tablet input until mouse input | bool | `false` |
| use_cpu_buffer | HW cursors use a CPU buffer (required on Nvidia): 0 off, 1 on, 2 auto (nvidia only) | int | `2` |
| warp_back_after_non_mouse_input | warp cursor back after non-mouse input moved it, then returning to mouse | bool | `false` |
| zoom_disable_aa | disable antialiasing when zooming (pixelated instead of blurry) | bool | `false` |

### Ecosystem (`ecosystem.`)

| name | description | type | default |
| --- | --- | --- | --- |
| no_update_news | disable the popup when you update hyprland | bool | `false` |
| no_donation_nag | disable the twice-yearly donation popup | bool | `false` |
| enforce_permissions | enable permission control | bool | `false` |

### Quirks (`quirks.`)

| name | description | type | default |
| --- | --- | --- | --- |
| prefer_hdr | report HDR mode as preferred: 0 off, 1 always, 2 gamescope only | int | `0` |
| skip_non_kms_dmabuf_formats | do not report dmabuf formats which cannot be imported into KMS | bool | `false` |

`prefer_hdr` fixes clients expecting HDR prior to start (whitescreen/flickering, breaks auto HDR).

### Debug (`debug.`) — developers only

| name | description | type | default |
| --- | --- | --- | --- |
| overlay | print the debug performance overlay. Disable VFR for accurate results. | bool | `false` |
| damage_blink | (epilepsy warning!) flash areas updated with damage tracking | bool | `false` |
| gl_debugging | OpenGL debugging with glGetError and EGL_KHR_debug (restart required) | bool | `false` |
| vfr | VFR status. Recommended to leave enabled | bool | `true` |
| disable_logs | disable logging to a file | bool | `true` |
| disable_time | disables time logging | bool | `true` |
| damage_tracking | redraw only needed bits: full - 2, monitor - 1, none - 0. Do **not** change. | int | `2` |
| enable_stdout_logs | enables logging to stdout | bool | `false` |
| manual_crash | set to 1 and then back to 0 to crash Hyprland | int | `0` |
| suppress_errors | do not display config file parsing errors | bool | `false` |
| log_damage | enables logging the damage | bool | `false` |
| disable_scale_checks | disables verification of the scale factors (pixel alignment/rounding errors) | bool | `false` |
| error_limit | limits the number of displayed config file parsing errors | int | `5` |
| error_position | position of the error bar: top - 0, bottom - 1 | int | `0` |
| colored_stdout_logs | enables colors in the stdout logs | bool | `true` |
| pass | enables render pass debugging | bool | `false` |
| full_cm_proto | claims support for all cm proto features (restart required) | bool | `false` |
| ds_handle_same_buffer | special case for direct scanout with unmodified buffer | bool | `true` |
| ds_handle_same_buffer_fifo | special case for direct scanout with unmodified buffer unlocks fifo | bool | `true` |
| fifo_pending_workaround | fifo workaround for empty pending list | bool | `false` |
| render_solitary_wo_damage | render solitary window with empty damage | bool | `false` |
| invalidate_fp16 | allow fp16 buffer invalidation: 0 not allowed, 1 allowed, 2 not allowed on nvidia | int | `1` |

### Experimental (`experimental.`)

| name | description | type | default |
| --- | --- | --- | --- |
| wp_cm_1_2 | allow wp-cm-v1 version 2 | bool | `false` |

### Input Capture (`input-capture.`)

| name | description | type | default |
| --- | --- | --- | --- |
| capture_modifiers | modifiers also captured and sent to the program | bool | `false` |
| enforce_barriers | throw a wayland error when an invalid barrier is received | bool | `true` |

---

## 7. Dispatchers (`Dispatchers.md`)

Dispatchers return action-description tables; fed into `hl.bind()` or `hl.dispatch()`. Contents not guaranteed stable.

### Parameter types

- **action**: `toggle` (default), `enable`/`on`, `disable`/`off`
- **Window**: window object | `class:...` | `initialclass:...` | `title:...` | `initialtitle:...` | `tag:...` | `pid:...` | `stableid:...` | `address:0x...` | `activewindow` | `floating` | `tiled`. Default: active window.
- **Workspace**: workspace object | workspace ID | workspace selector.
- **Direction**: `l` / `r` / `u` / `d`.
- **Monitor**: monitor object | monitor ID | direction | name | `desc:` + description | `current` | relative `+1` / `-2`.

### General (`hl.dsp.`)

| method | description |
| --- | --- |
| `exec_cmd(cmd, rules?)` | execute a command (`sh -c`). Rules = table of window-rule effects to apply. |
| `exec_raw(cmd)` | execute a raw command (no `sh -c`). |
| `focus({ direction })` | move the focus in a direction |
| `focus({ monitor })` | move the focus to a monitor |
| `focus({ workspace, on_current_monitor? })` | move the focus to a workspace |
| `focus({ window })` | move the focus to a window |
| `focus({ urgent_or_last })` | move the focus to an urgent, or last window |
| `focus({ last })` | move the focus to the last window |
| `exit()` | quit Hyprland (prefer `hyprshutdown`; uwsm users: use `uwsm stop`) |
| `submap(name)` | move to a submap |
| `pass({ window? })` | pass the shortcut to a window |
| `send_shortcut({ mods, key, window? })` | send a specific shortcut to a window |
| `send_key_state({ mods, key, state, window? })` | like send_shortcut, but you control `down` / `up` |
| `layout(message)` | send a layout message as a string |
| `dpms({ action?, monitor? })` | toggle monitors on/off (idle-screensaver style) |
| `event(string)` | send an event to socket2 |
| `global(string)` | activate a dbus global shortcut |
| `force_idle(seconds)` | sets elapsed time for all idle timers, ignoring idle inhibitors; returns to normal on next activity. Do not use with a keybind directly. |
| `no_op()` | does nothing. Useful for conditional binds. |
| `force_renderer_reload()` | force reloads the renderer on all monitors |
| `release_input_capture()` | releases any active input capture session |

### Window (`hl.dsp.window.`)

| method | description |
| --- | --- |
| `close({ window? })` | graceful close request |
| `kill({ window? })` | kill process with `SIGKILL` |
| `signal({ signal, window? })` | send a POSIX signal to the window's process |
| `float({ action?, window? })` | set floating state |
| `fullscreen({ mode?, action?, layout_aware?, window? })` | `mode`: `"maximized"`/`"fullscreen"`; `action`: toggle/set/unset; `layout_aware`: `true` (default)/`false` |
| `fullscreen_state({ internal, client, action?, layout_aware?, window? })` | precise internal/client FS state; see Fullscreenstate |
| `pseudo({ action?, window? })` | set pseudotiling state |
| `move({ direction, group_aware?, window? })` | move window in a direction (`group_aware = true` puts windows in/out of groups) |
| `move({ workspace, follow?, window? })` | move window to a workspace |
| `move({ monitor, follow?, window? })` | move window to a monitor |
| `move({ x, y, relative?, window? })` | move window by / to a coord |
| `move({ into_group = direction, window? })` | move window into a group in a direction |
| `move({ into_or_create_group = direction, window? })` | move into a group, or create one if none in that direction |
| `move({ out_of_group, window? })` | `true` for directionless, or a direction |
| `swap({ direction })` | swap with a window in a direction |
| `swap({ target })` | swap with another window |
| `swap({ next })` | swap with next window |
| `swap({ prev })` | swap with previous window |
| `center({ window? })` | center the current window on screen |
| `cycle_next({ next?, tiled?, floating?, window? })` | focus the next window |
| `tag({ tag, window? })` | tag a window |
| `clear_tags({ window? })` | clear all tags from a window |
| `toggle_swallow()` | toggle all swallowed windows visible |
| `pin({ action?, window? })` | pin a window |
| `alter_zorder({ mode, window? })` | mode: `"top"` or `"bottom"` |
| `set_prop({ prop, value, window? })` | set a window property |
| `deny_from_group({ action? })` | deny a window from entering a group |
| `drag()` | begin interactive drag (mouse binds) |
| `resize()` | begin interactive resize (mouse binds) |
| `resize({ keep_aspect_ratio })` | interactive resize overriding window's keep_aspect_ratio prop |
| `resize({ x, y, relative?, window? })` | resize a window |

### Workspace (`hl.dsp.workspace.`)

| method | description |
| --- | --- |
| `rename({ workspace, name? })` | rename a workspace |
| `change_id({ workspace, id })` | change a workspace's ID. Cannot be an ID already in use. Must be > 0. |
| `move({ workspace?, monitor })` | move a workspace to a monitor |
| `swap_monitors({ monitor1, monitor2 })` | swap current workspaces of two monitors |
| `toggle_special(special_name)` | toggle a special workspace by name |

### Group (`hl.dsp.group.`)

| method | description |
| --- | --- |
| `toggle({ window? })` | toggle a group |
| `next({ window? })` | next window in a group |
| `prev({ window? })` | previous window in a group |
| `active({ index, window? })` | switch to a window in a group, indexed |
| `move_window({ forward?, window? })` | move a window in the group order |
| `lock({ action?, window? })` | lock a group |
| `lock_active({ action? })` | lock the active group |

### Cursor (`hl.dsp.cursor.`)

| method | description |
| --- | --- |
| `move_to_corner({ corner, window? })` | move cursor to a corner of the window (0-3) |
| `move({ x, y })` | move cursor to a coordinate |

### Warnings

- `exit`/terminating Hyprland directly: uwsm users should use `uwsm stop` (or `loginctl terminate-user ""`) to preserve ordered shutdown.
- DPMS / forceidle with a keybind directly is not recommended — use a timer:

```lua
hl.bind("...", function()
                 hl.timer(function()
                   hl.dispatch(hl.dsp.dpms({ action = "disable" }))
                 end, {timeout = 500, type = "oneshot"})
               end)
```

### Grouped (tabbed) windows

`hl.dsp.group.toggle()` creates a group (i3wm "tabbed"). `lock` stops new windows entering; `deny_from_group` prevents a window being added/becoming a group.

### Workspace selectors (9 choices)

- ID: `1`, `2`, `3`
- Relative ID: `+1`, `-3`, `+100`
- Monitor-relative: `m+1`, `m-2` (relative), `m~3` (absolute)
- Monitor-relative incl. empty workspaces: `r+1`, `r~3`
- Open-workspace-relative: `e+1`, `e-10`, `e~2`
- Name: `name:Web`, `name:Better anime`
- Previous: `previous`, `previous_per_monitor`
- First empty: `empty`; suffix `m` = search only on monitor, `n` = _next_ available empty (e.g. `emptynm`)
- Special: `special` or `special:name`

Numerical workspaces allowed only 1–2147483647 (inclusive); `0` and negatives are invalid.

### Special workspaces

Scratchpad toggled on any monitor. Named special workspaces limited to **97 at a time**.

```lua
hl.bind("SUPER + C", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
```

### Executing with rules

`exec_cmd(cmd, rules)` records the PID of the spawned process; forked processes may not match. Some windows work better/worse.

```lua
hl.bind("SUPER + E", hl.dsp.exec_cmd("kitty", { float = true, move = {0, 0} }))
```

### set_prop

Props = any dynamic window-rule effect. `value` is a string.

```lua
{ prop = "no_anim", value = "1" }
{ prop = "no_anim", value = "1", window = "class:abc" }
```

Expanded props:
- `border_color` → `active_border_color`, `inactive_border_color`
- `opacity` → `opacity`, `opacity_inactive`, `opacity_fullscreen`, `opacity_override`, `opacity_inactive_override`, `opacity_fullscreen_override`

### Fullscreenstate

Decouples Hyprland's internal state (`internal`) from what the client receives (`client`).

| Value | State | Description |
| --- | --- | --- |
| -1 | Current | Maintains the current fullscreen state. |
| 0 | None | Window allocates the space defined by the current layout. |
| 1 | Maximized | Window takes up the entire working space, keeping the margins. |
| 2 | Fullscreen | Window takes up the entire screen. |

- `{internal = 2, client = 0}`: fullscreen the app while the client stays non-fullscreen (prevents Chromium presentation mode).
- `{internal = 0, client = 2}`: window stays non-fullscreen, client is told it's fullscreen within the window.

### FSMODE_MAX

Internal state when a client requests `Fullscreen` while internal mode is `Maximized`. Next un-FS returns to `Maximized` instead. Example: fullscreening a video in a maximized window.

### Fullscreen Handlers

Some layouts (e.g. scrolling) allow FS handling other than the default; select via `layout_aware` in fullscreen dispatchers.

---

## 8. Autostart (`Autostart.md`) — replaces hyprlang `exec-once`/`exec`

```lua
hl.on("hyprland.start", function ()
  hl.exec_cmd(terminal)
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("waybar & hyprpaper & firefox") -- multiple commands in one string still work
end)
```

- `hl.exec_cmd()` spawns an **asynchronous** process — no need for `& disown`.
- Spawn on exit via `hl.on("hyprland.shutdown", ...)`.
- For user services use systemd autostart instead.

---

## 9. Animations (`Animations.md`)

### Declaration

```lua
hl.animation({ leaf = STRING, enabled = BOOLEAN, speed = FLOAT, curve = STRING[, style = STRING] })
```

- `leaf`: scope of the animation (see tree below).
- `enabled`: `true`/`false` (if `false`, further args can be omitted; `enabled = 0` also shown).
- `speed`: animation duration in ds (**1ds = 100ms**), e.g. `speed = 1` = 100ms.
- `bezier` / `spring`: curve name (see Curves). (Doc signature uses `curve`; examples use `bezier`/`spring`.)
- `style` (optional): animation style.

```lua
hl.animation({ leaf = "workspaces", enabled = true, speed = 8, bezier = "my_epic_bezier" })
hl.animation({ leaf = "windows", enabled = true, speed = 10, spring = "my_epic_spring", style = "slide"})
hl.animation({ leaf = "fade", enabled = 0 })
```

### Animation tree

Unset animations inherit their parent's values.

```
global
  ↳ windows - styles: slide, popin, gnomed
    ↳ windowsIn - window open
    ↳ windowsOut - window close
    ↳ windowsMove - everything in between (moving, dragging, resizing)
  ↳ layers - styles: slide, popin, fade
    ↳ layersIn - layer open
    ↳ layersOut - layer close
  ↳ fade
    ↳ fadeIn - fade in for window open
    ↳ fadeOut - fade out for window close
    ↳ fadeSwitch - fade on changing activewindow and its opacity
    ↳ fadeShadow - fade on changing activewindow for shadows
    ↳ fadeGlow - fade on changing activewindow for glow
    ↳ fadeDim - easing of the dimming of inactive windows
    ↳ fadeLayers - fade on layers
      ↳ fadeLayersIn - fade in for layer open
      ↳ fadeLayersOut - fade out for layer close
    ↳ fadePopups - fade on wayland popups
      ↳ fadePopupsIn - fade in for wayland popup open
      ↳ fadePopupsOut - fade out for wayland popup close
    ↳ fadeDpms - fade when dpms is toggled
  ↳ border - animating the border's color switch speed
  ↳ borderangle - animating the border's gradient angle - styles: once (default), loop
  ↳ shadowangle - animating the shadow's gradient angle - styles: once (default), loop
  ↳ glowangle - animating the glow's gradient angle - styles: once (default), loop
  ↳ workspaces - styles: slide, slidevert, fade, slidefade, slidefadevert
    ↳ workspacesIn
    ↳ workspacesOut
    ↳ specialWorkspace
      ↳ specialWorkspaceIn
      ↳ specialWorkspaceOut
  ↳ zoomFactor - animates the screen zoom
  ↳ monitorAdded - monitor added zoom animation
```

> `loop` style for `*angle` animations forces constant rendering at screen refresh rate — CPU/GPU/battery impact even with animations disabled or decorations invisible.

### Curves

```lua
-- cubic Bézier, defined by 2 configurable points
hl.curve(NAME, { type = "bezier", points = { {X0, Y0}, {X1, Y1} } })
-- spring
hl.curve(NAME, { type = "spring", mass = MASS, stiffness = STIFF, dampening = DAMP })
```

More stiffness = more speed; more dampening = less bounce. Keep mass at 1.

```lua
hl.curve("overshoot", { type = "bezier", points = { {0.5, 0.9}, {0.1, 1.1} } })
hl.curve("rubber", { type = "spring", mass = 1, stiffness = 70, dampening = 10 })
```

### Style extras

- `popin` (windows): min start percentage — `style = "popin 80%"` (80% → 100% of size).
- `slide`, `slidevert`, `slidefade`, `slidefadevert` (workspaces): movement percentage — `style = "slidefade 20%"` (20% of screen width).
- `slide` (windows, layers): forced side — `style = "slide left"` (`top`/`bottom`/`left`/`right`).

---

## 10. Devices (`Devices.md`)

```lua
hl.device({
    name = "my-epic-keyboard",
    sensitivity = -0.5
})
```

- `name` from `hyprctl devices`.
- Any option from `input` (and subcategories like `input.touchpad`) is valid **EXCEPT**:
  - `force_no_accel`
  - window-management options: `follow_mouse`, `follow_mouse_threshold`, `float_switch_override_focus`, `mouse_refocus`, `special_fallthrough`, etc.
- `output` on tablets binds them to outputs — use the name of the **Tablet**, not `Tablet Pad` or `Tablet Tool`.

Additional per-device-only properties:

| name | scope | description | default |
| --- | --- | --- | --- |
| `enabled` | mice / touchpads / touchdevices / keyboards | enables/disables the device (connects/disconnects from on-screen cursor) | Enabled |
| `keybinds` | devices that send key events | enables/disables keybinds for the device | Enabled |
| `tags` | keyboards / pointers | grouping and alt-names for device-specific binds; comma separated list | `""` |

> Per-device layouts don't alter the keybind keymap by default (global `us` + per-device `fr` → binds act as `us`). Set `resolve_binds_by_sym = 1` to bind by symbol.

---

## 11. Environment variables (`Environment-variables.md`)

```lua
hl.env("GTK_THEME", "Nord")
```

- Set **before** Display Server initialization.
- Reference existing vars with `os.getenv()`: `hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR").."/ssh-agent.socket")`
- **Avoid** `/etc/environment` (leaks Wayland-specific env into Xorg sessions).
- uwsm users: put env in `~/.config/uwsm/env` (theming, xcursor, Nvidia, toolkit) and `~/.config/uwsm/env-hyprland` (`HYPR*`, `AQ_*`), format `export KEY=VAL`.

### Hyprland vars

- `hl.env("HYPRLAND_TRACE", "1")` — more verbose logging
- `hl.env("HYPRLAND_NO_RT", "1")` — disable realtime priority
- `hl.env("HYPRLAND_NO_SD_NOTIFY", "1")` — disable `sd_notify` (systemd)
- `hl.env("HYPRLAND_NO_SD_VARS", "1")` — disable management of systemd/dbus activation env vars
- `hl.env("HYPRLAND_CONFIG", "/path/to/hyprland.lua")` — config location override

### Aquamarine vars

- `AQ_TRACE` `1` — verbose logging
- `AQ_DRM_DEVICES` — colon-separated DRM device paths, first = primary, e.g. `/dev/dri/card1:/dev/dri/card0`
- `AQ_FORCE_LINEAR_BLIT` `0` — disable forcing linear explicit modifiers on Multi-GPU buffers (Nvidia workaround)
- `AQ_MGPU_NO_EXPLICIT` `1` — disable explicit syncing on mgpu buffers
- `AQ_NO_MODIFIERS` `1` — disable modifiers for DRM buffers
- `AQ_NO_KMS_REQUIREMENT` `1` — allow starting on headless GPUs without KMS

### Toolkit backend

- `GDK_BACKEND = "wayland,x11,*"` (GTK)
- `QT_QPA_PLATFORM = "wayland;xcb"` (Qt)
- `SDL_VIDEODRIVER = "wayland"` (SDL2; set `x11` if older SDL games break)
- `CLUTTER_BACKEND = "wayland"`

### XDG

- `XDG_CURRENT_DESKTOP = "Hyprland"`
- `XDG_SESSION_TYPE = "wayland"`
- `XDG_SESSION_DESKTOP = "Hyprland"`

Broken portal with no errors → XDG env likely wrong. uwsm sets these automatically.

### Qt

- `QT_AUTO_SCREEN_SCALE_FACTOR = "1"` — automatic scaling by pixel density
- `QT_QPA_PLATFORM = "wayland;xcb"`
- `QT_WAYLAND_DISABLE_WINDOWDECORATION = "1"` — no decorations
- `QT_QPA_PLATFORMTHEME = "qt5ct"` — theme from qt5ct (use with Kvantum)

### NVIDIA

- `GBM_BACKEND = "nvidia-drm"` and `__GLX_VENDOR_LIBRARY_NAME = "nvidia"` — force GBM backend
- `LIBVA_DRIVER_NAME = "nvidia"` — hw acceleration
- `__GL_GSYNC_ALLOWED` — G-Sync/VRR control
- `__GL_VRR_ALLOWED` — Adaptive Sync; recommended `"0"` for some games
- `AQ_NO_ATOMIC = "1"` — legacy DRM interface instead of atomic. **NOT recommended.**

### Theming

- `GTK_THEME` — set GTK theme manually
- `XCURSOR_THEME` — cursor theme (installed + readable)
- `XCURSOR_SIZE` — cursor size

---

## 12. Expanding functionality (`Expanding-functionality.md`)

### Events (`hl.on`)

```lua
hl.on("window.active", function(w)
  hl.notification.create({ text = "Window focused: " .. w.title, timeout = 5000, icon = "ok" })
end)
```

Multiple parameters example:

```lua
hl.on("workspace.move_to_monitor", function(ws, m)
  hl.notification.create({ text = "Workspace: " .. ws.name .. " moved to a monitor at x: " .. m.position.x, timeout = 4000, icon = "ok" })
end)
```

Full event list:

| Event | Description | Parameters |
| --- | --- | --- |
| hyprland.start | Emitted once on start | None |
| hyprland.shutdown | Emitted once before Hyprland exiting | None |
| window.open | Emitted when a window is fully initialized with window rules applied. | Window |
| window.open_early | Emitted when a window is created and mapped, but **before** window rules are applied. | Window |
| window.close | Emitted when a window is closed. It may still be visible during its closing animation. | Window |
| window.destroy | Emitted when a window is removed from the compositor. For windows with a close animation, fires after the animation completes. | Window |
| window.kill | Emitted when a window is forcefully killed via hyprctl kill. | Window |
| window.active | Emitted when the active window changes. | Window, int (focus reason) |
| window.urgent | Emitted when a window requests an `urgent` state. | Window |
| window.title | Emitted when a window title changes. | Window |
| window.class | Emitted when a window class changes. | Window |
| window.pin | Emitted when a window is pinned or unpinned. | Window |
| window.fullscreen | Emitted when the fullscreen status of a window changes. | Window |
| window.update_rules | Emitted when a window's rules are re-evaluated, e.g. when its title or class changes. | Window |
| window.move_to_workspace | Emitted when a window is moved to a different workspace. | Window, Workspace |
| window.bell | Emitted when a window rings the system bell, even if it's muted. | Window |
| layer.opened | Emitted when a layer surface is opened. | LayerSurface |
| layer.closed | Emitted when a layer surface is closed. | LayerSurface |
| monitor.added | Emitted when a monitor is connected and ready. | Monitor |
| monitor.removed | Emitted when a monitor is disconnected and removed. | Monitor |
| monitor.focused | Emitted when the active monitor changes. | Monitor |
| monitor.layout_changed | Emitted when the monitor arrangement changes (monitor added/removed, resolution/refresh changed, config reload with different rules). | None |
| workspace.active | Emitted when the active workspace on a monitor changes. | Workspace |
| workspace.special_active | Emitted when the opened special workspace on a monitor changes. Workspace of nil means no special workspace is open. | Workspace, Monitor |
| workspace.created | Emitted when a workspace is created. | Workspace |
| workspace.removed | Emitted when a workspace is removed. | Workspace |
| workspace.move_to_monitor | Emitted when a workspace is moved to a different monitor. | Workspace, Monitor |
| config.reloaded | Emitted when the config has been reloaded **and applied**. | None |
| config.props_refreshed | Emitted when a prop refresh event is executed. | Bool: executed as scheduled (`false` if premature via helper) |
| keybinds.submap | Emitted when the active submap changes. Empty string = default submap restored. | String: Submap Name |
| screenshare.state | Emitted when a screenshare session starts or stops. | Bool: Active, Integer: Type, String: Name |
| input.keyboard.key | Emitted when a key is pressed or released. | Integer: XKB keycode, Integer: Unix timestamp, Integer: released (0), pressed (1), repeated (2) |

### Convenience functions

- `hl.get_config()`
- `hl.get_active_window()`
- `hl.get_windows()`
- `hl.get_window(selector)`
- `hl.get_urgent_window()`
- `hl.get_workspaces()`
- `hl.get_workspace(selector)`
- `hl.get_active_workspace()`
- `hl.get_active_special_workspace()`
- `hl.get_monitors()`
- `hl.get_monitor(selector)`
- `hl.get_active_monitor()`
- `hl.get_monitor_at({ x = num, y = num })`
- `hl.get_monitor_at_cursor()`
- `hl.get_cursor_pos()`
- `hl.get_last_window()`
- `hl.get_last_workspace()`
- `hl.get_layers()`
- `hl.get_workspace_windows(workspace_selector)`
- `hl.get_current_submap()`
- `hl.version()`
- `hl.exec_cmd()`
- `hl.exec_scheduled_prop_refresh_immediately()`
- `hl.get_loaded_plugins()`
- `hl.is_key_down(key = num|str)`

Return values (classes/parameters): use the LSP (see wiki Start → autocompletions).

### Dynamically changing a config option

`hl.get_config("general.layout")` returns the underlying type's representation. `gaps_in = 3` returns:

```lua
{ top = 3, left = 3, right = 3, bottom = 3 }
```

Runtime toggle example (gaps 0 ↔ 3):

```lua
hl.bind(mainMod .. " + SHIFT + G", function()
    local gapsInValueTable = hl.get_config("general.gaps_in")
    if gapsInValueTable.top == 3 then
        hl.config({ general = { gaps_in = 0 } })
    else
        hl.config({ general = { gaps_in = 3 } })
    end
end)
```

### Prop Refresh

- A prop refresh updates/refreshes many configurable options (keyboard layouts, device configs, monitor states, window gaps, etc.).
- E.g. creating a workspace rule schedules a single prop refresh at the **end of the current event** (your Lua function). Code after the rule creation sees the old value.
- Force immediate: `hl.exec_scheduled_prop_refresh_immediately()` — removes the scheduled event from the loop; overuse causes slowdowns.

### Timers

```lua
local demoTimer = hl.timer(function()
  print("hello from timer")
end, { timeout = 1000, type = "repeat" })

demoTimer:set_enabled(false)
-- toggle:
demoTimer:set_enabled(not demoTimer:is_enabled())
```

### Example combining it all

```lua
hl.bind("SUPER + X", function()
  local w = hl.get_active_window()
  if w ~= nil and w.title == "htop" do
    hl.dispatch(hl.dsp.window.float({ action = "set" }))
  else
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  end
end)
```

### Sockets (IPC)

Lua is recommended over IPC (faster, less buggy, more APIs, more integrated). See the IPC page for sockets.

---

## 13. Uncommon tips & tricks (`Uncommon-tips-and-tricks.md`)

Highlights (full code in source):

- **Caps Lock remap** via `kb_options` (`ctrl:nocaps`, etc.) — same as Binds page.
- **Minimize via special workspace** — single keybind toggles `special:minimized` using `hl.get_workspace("special:minimized")`, `hl.dsp.window.tag`, `clear_tags`, `move`.
- **Game-mode hotkey** — keybind toggling `hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 } })`; re-enables via `hl.exec_cmd("hyprctl reload")`.
- **Per-workspace layouts** — `hl.workspace_rule({ workspace = "2", layout = "scrolling" })`.
- **Cycle layout for current workspace** — uses `hl.get_active_workspace()`, `hl.get_active_special_workspace()`, `workspace.tiled_layout`, `workspace.id`/`workspace.name`/`workspace.special`.
- **Per-layout bindings** — `hl.dsp.layout("swapcol l")`, `"swapsplit"`, `"togglesplit"`, `"cycleprev"`, `"cyclenext"` dispatch based on `workspace.tiled_layout`.
- **Config versioning** — `hl.version()` conditionals, e.g. `if hl.version() == "0.55.2" then ...`.
- **Glass magnifier zoom** — `hl.get_config("cursor.zoom_factor")` + `hl.config({ cursor = { zoom_factor = ... } })`.

---

## 14. Basics index (`_index.md`)

"This section is for basics - things you will definitely want to configure first." (No technical content.)

---

## 15. Migration guidance & gotchas (consolidated)

1. **`source` → Lua**: the wiki does not document a `source` equivalent; use standard Lua (`dofile`, `require`) for modular configs. `hl.config()` calls merge — call it as many times as you like.
2. **Variables**: hyprlang `$VAR` → Lua local variables (`local mainMod = "SUPER"`, string concatenation with `..`). No more `$` syntax.
3. **`exec-once`/`exec`**: replaced by `hl.on("hyprland.start", ...)` + `hl.exec_cmd()` (async, no `& disown` needed) and `hl.dsp.exec_cmd()` in binds.
4. **Bind variants collapsed into flags**: `bindl`→`{locked=true}`, `bindr`→`{release=true}`, `bindt`→`{transparent=true}`, `binds`→`{repeating=true}`, `bindm`→`{mouse=true}` (the `c`/`g` flags map to `click`/`drag` + `binds.drag_threshold`). `catchall` binds and `mouse_up/down` are unchanged conceptually.
5. **`monitor` → `hl.monitor({...})`** — same fields as hyprlang (output, mode, position, scale, transform, mirror, bitdepth, cm, vrr, etc.), `disabled` replaces `disable`.
6. **`windowrule` → `hl.window_rule`**: hyprlang `windowrule = float, class(...)` became structured `match` (props) + effects tables; rules return handles (`set_enabled`/`is_enabled`) — named rules only.
7. **`layerrule` → `hl.layer_rule`**, **`workspacerule` → `hl.workspace_rule`** (single-table form in examples).
8. **Colors**: 4 formats supported — `"#rrggbb[aa]"`, `"rgb(rrggbb)"`/decimal, `"rgba(...)"`/decimal, or legacy `0xAARRGGBB`. `gradient` type accepts `{ colors = {...}, angle = ... }`.
9. **Animations**: `bezier = name` + `animation = name, onetime, speed, curve, style` → `hl.curve(NAME, {...})` + `hl.animation({ leaf, enabled, speed, bezier/spring, style })`.
10. **Removed options**: `gestures.workspace_swipe`, `workspace_swipe_fingers`, `workspace_swipe_min_fingers` → use `hl.gesture({ fingers, direction, action })`.
11. **Keybind callbacks must not block** the compositor event loop (no `io.popen`, `wl-paste`, sleeps, network I/O inside bind lambdas — use `hl.dsp.exec_cmd` or `hl.timer`).
12. **`hl.unbind` is case-sensitive**.
13. **Runtime configurability**: everything is scriptable — `hl.config()`, `hl.get_config()`, `hl.dispatch()`, `hl.timer()`, `hl.on()` events replace the old "hyprctl keyword/socket2" workflows.
14. **uwsm**: avoid `exit` dispatcher / direct process termination; use `uwsm stop`; keep env vars out of `hyprland.lua`.
15. **Named vs anonymous rules**: named rules always evaluated before anonymous and take precedence; effects from later matches win.
16. **Opacity math**: rules multiply; use `override` suffix for absolutes.
17. **`hyprctl eval '...'`** accepts Lua snippets (e.g. `hl.unbind(...)`) for dynamic keybinding.
