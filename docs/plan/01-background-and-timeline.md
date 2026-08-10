# 01 — Background and Timeline

## 1.1 What happened

Hyprland's configuration was historically written in **hyprlang**, a custom key/value language
(`.conf` files with `category { key = value }` blocks, `$VAR` variables, `bind = ...` lines,
`source =` includes).

Starting with **Hyprland 0.55.0** (released 2026-05-09), the compositor config was rewritten on
top of **Lua** (via `sol2`). The config file is now `~/.config/hypr/hyprland.lua` and the whole
config surface is exposed through a single global table, **`hl`**:

```lua
hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1.0 })
hl.config({ general = { gaps_in = 2, gaps_out = 4, border_size = 2 } })
hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"), { description = "Open terminal" })
```

This is the biggest change to Hyprland configuration since its creation — comparable to
Neovim's `init.vim` → `init.lua` migration.

## 1.2 Official timeline

| Date | Event |
|---|---|
| 2024-11 | "Breaking changes tracker" opened (hyprwm/Hyprland#8424). |
| 2026-04-26 | Lua branch merged — PR #13817, announced in "[Lua-ification of Hyprland configs](https://hypr.land/news/26_lua/)". |
| 2026-05-09 | **v0.55.0 released.** Lua optional; `.conf` still loads if no `hyprland.lua` exists. Precedence is checked **once at startup**. |
| 2026-05-13 | First community converter appears (`hyprlang2lua`). |
| 2026-06-04 | `hyprconf2lua` (Python) on PyPI. |
| 2026-07-20 | v0.56.0 — no breaking changes; adds Lua REPL in `hyprctl`, `hyprctl config full-reload`, more `hl.*` APIs. |
| 2026-07-27 | v0.56.1 — **deprecation notice shown for `.conf` configs**; fixes `package.path` nuking. |
| 2026-08-05 | v0.56.2 — missing Lua stub fix. (This is the version installed in HyprFlux.) |

## 1.3 Official statements that matter

> "If you don't have a `hyprland.lua` config file, your old `hyprland.conf` will be loaded, business
> as usual." — but this is decided once at startup; a `.lua` launch will not fall back to legacy
> until restart.

> "The old hyprlang syntax will continue to be supported for **1–2 releases** starting from 0.55.
> After that, hyprlang will be dropped. **New config features will also not be added to hyprlang
> anymore.**"

> v0.56.1 release note: "add a deprecation notice to `.conf` configs" (hyprwm/Hyprland#15538).

## 1.4 What changed vs what did NOT change

### Changed (compositor only)
- Config file: `hyprland.conf` → `hyprland.lua`
- Everything config-side: variables, binds, monitors, rules, animations, autostart, env
- `hyprctl` gained `eval 'lua'`, a REPL, `config full-reload`
- New capabilities that hyprlang will never get: events (`hl.on`), timers, live rule handles
  (`:set_enabled`), user-defined layouts, gestures, runtime `hl.config()` toggles

### NOT changed
- **Hyprlock, Hypridle, Hyprpaper** — still hyprlang. Official design: "most of those tools are
  simple in nature and work totally fine with a simple syntax". Your `hyprlock.conf`,
  `hyprlock-1080p.conf`, `hypridle.conf`, `application-style.conf` stay as-is.
- **hyprpm plugins** — C++ ABI-based, unrelated to the config format. But their config *sections*
  are now exposed under `hl.plugin.<name>` (Lua), and plugin dispatchers are Lua-only.
- **hyprctl dispatch** — still works for scripts (legacy), but the preferred path is Lua.
- **Waybar, rofi, swaync, quickshell** configs — untouched.
- **The X11/other-ecosystem world** — untouched.

### 0.55 breaking config changes (regardless of format)
- `dwindle:pseudotile` removed (did nothing)
- `decoration:shadow:ignore_window` removed (now default-on)
- `render:cm_fs_passthrough` removed
- `misc:vfr` moved to `debug:vfr`
- `gestures.workspace_swipe`, `workspace_swipe_fingers`, `workspace_swipe_min_fingers` **removed** →
  replaced by the `hl.gesture()` API (see doc 11)

## 1.5 Why Lua (official rationale + practical)

1. **Expressiveness**: loops, functions, closures, string concat — 152 binds become ~60 lines of
   looped Lua; conditions can be evaluated at runtime, not parse time.
2. **Runtime mutability**: `hl.config()` applies live, rule handles toggle without reload.
3. **Integration**: `hl.on()` events replace socket2 scraping; `hl.timer()` replaces cron hacks.
4. **Performance**: keybinds can dispatch directly (`hl.dispatch(hl.dsp...)`) instead of spawning
   a `hyprctl`/`sh` process per keypress — measurable on slow binds.
5. **Ubiquity**: Lua is a small, stable, widely-known language with a rich stdlib.

## 1.6 Ecosystem response (who already moved)

- **nwg-displays 2.4+** (you have it): writes `monitors.lua` + `workspaces.lua`; README says use
  `require("monitors")` in `hyprland.lua`. Your live `~/.config/hypr/monitors.lua` is proof.
- **hyprmoncfg** v1.5.0+: auto-detects Lua vs legacy format.
- **Dotfile projects**: ML4W, HyDE, Caelestia, Omarchy, HyprVim all shipped Lua rewrites in
  May–July 2026.
- **Waybar** had a 0.55 dispatch-compat fix (Alexays/Waybar#5013).
- **HyprSettings** (GUI editor) is the notable laggard — still `.conf`-era.

## 1.7 What this means for HyprFlux

- The repo currently ships a pure-hyprlang config (115 files under `.config/hypr`, zero `.lua`).
- The live machine already has `monitors.lua` written by nwg-displays — the ecosystem has started.
- `modules/19-monitors.sh` and `dotsSetup.sh` still write/expect `.conf` — must be updated.
- **Deadline pressure**: hyprlang drops within ~1 release after 0.56. The migration should land
  before the next Hyprland major (0.57).

Next: [02-lua-syntax-crash-course.md](02-lua-syntax-crash-course.md)
