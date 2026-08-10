# 15 — HyprFlux-Specific Migration Plan

This document is the *executable* plan for THIS repository (HyprFlux). It uses the full inventory
of the repo's `.config/hypr` tree (115 files) plus your live `~/.config/hypr` differences.

## 15.1 Inventory (baseline, verified 2026-08-10)

| File | Size | Content | → Lua target | Phase |
|---|---|---|---|---|
| `hyprland.conf` | 1.8 KB | entrypoint, 15 `source=` lines, initial-boot exec-once | `hyprland.lua` | 1/6 |
| `configs/Keybinds.conf` | 7.4 KB | **93 binds** (window ops, media, workspaces 1–10, mouse) | `configs/keybinds.lua` | 3 |
| `UserConfigs/UserKeybinds.conf` | 6.3 KB | **46 binds** (apps, features, toggles, scripts) | `UserConfigs/user-keybinds.lua` | 3 |
| `UserConfigs/Laptops.conf` | 3.2 KB | **13 binds**, `device{ $Touchpad_Device }` | `UserConfigs/laptops.lua` | 3 |
| `UserConfigs/WindowRules.conf` | 13.1 KB | **96 windowrule + 3 layerrule** (tag-based) | `UserConfigs/window-rules.lua` | 4 |
| `UserConfigs/WindowRules-old.conf` | 9.3 KB | legacy `windowrulev2` (~100 lines, NOT sourced) | archive or delete | 6 |
| `UserConfigs/UserSettings.conf` | 2.6 KB | dwindle/master, input, gestures, misc, binds, xwayland, render, cursor, debug | `UserConfigs/user-settings.lua` | 2 |
| `UserConfigs/UserDecorations.conf` | 1.0 KB | general border/gaps, decoration, group; sources colors | `UserConfigs/user-decorations.lua` | 2 |
| `UserConfigs/UserAnimations.conf` | 876 B | 7 beziers, 9 animations | `UserConfigs/user-animations.lua` | 2 |
| `UserConfigs/ENVariables.conf` | 3.6 KB | ~23 `env =` | `UserConfigs/env-variables.lua` | 2 |
| `UserConfigs/Startup_Apps.conf` | 1.7 KB | **9 exec-once** | `UserConfigs/startup-apps.lua` | 5 |
| `UserConfigs/01-UserDefaults.conf` | 716 B | `$term/$files/$Search_Engine/$edit` | `UserConfigs/user-defaults.lua` (locals) | 2 |
| `UserConfigs/00-Readme` | 904 B | user instructions | update | 6 |
| `UserConfigs/LaptopDisplay.conf` | 162 B | eDP-1 monitor (lid flow) | into `laptops.lua` | 3 |
| `UserConfigs/WorkSpaceRules` | 1.3 KB | guide only (not sourced) | `UserConfigs/workspace-rules.lua` | 4 |
| `hyprflux-colors/hyprflux-colors.conf` | 497 B | 17 colors | `hyprflux-colors.lua` (module) | 2 |
| `monitors.conf` | 2.4 KB | nwg-displays managed | `monitors.lua` (already exists live) | 5 |
| `workspaces.conf` | 1.2 KB | nwg-displays managed | `workspaces.lua` | 5 |
| `animations/*.conf` (16) | 455–2.1 KB | presets | `animations/*.lua` | 6 |
| `Monitor_Profiles/default.conf` | 2.4 KB | profile backups | `Monitor_Profiles/*.lua` | 5 |
| `hyprlock.conf`, `hyprlock-1080p.conf`, `hypridle.conf`, `application-style.conf` | — | **keep hyprlang (NOT compositor)** | unchanged | — |
| `scripts/*.sh` (46) | — | use `hyprctl dispatch/keyword` heavily | re-point (15.7) | 3–6 |
| `UserScripts/*` (19) | — | user scripts | only if they call hyprctl dispatch | 6 |

Live-only files to preserve: `scripts/refresh-rate.sh` (+ its systemd unit wiring in
Startup_Apps), `.initial_startup_done` marker, live `ENVariables` additions (`AQ_DRM_DEVICES`,
Mesa pinning, `HYPRCURSOR_SIZE=24`), live `UserDecorations` (border_size=2, active_border colors),
live `kb_options = ctrl:nocaps`, live `01-UserDefaults` (`$term = kitty`), live `WindowRules`
rule 97 (Playwright chromium → workspace 6 silent).

## 15.2 Target tree

```
~/.config/hypr/
├── hyprland.lua                  ← entrypoint (requires everything)
├── monitors.lua                  ← nwg-displays generated
├── workspaces.lua                ← nwg-displays generated
├── hyprflux-colors.lua           ← returns palette table
├── configs/keybinds.lua
├── UserConfigs/
│   ├── user-defaults.lua  env-variables.lua  user-settings.lua
│   ├── user-decorations.lua  user-animations.lua
│   ├── user-keybinds.lua  laptops.lua  window-rules.lua
│   ├── workspace-rules.lua  startup-apps.lua  00-Readme
├── Monitor_Profiles/*.lua
├── animations/*.lua
└── (unchanged: hyprlock* .conf, hypridle.conf, application-style.conf,
     scripts/, UserScripts/, wallpaper_effects/, hyprlock/)
```

`hyprland.lua` bootstrap (order matters — env first, autostart last):

```lua
-- HyprFlux — https://github.com/ahmad9059/HyprFlux
local Home = os.getenv("HOME")

require("UserConfigs.env-variables")      -- hl.env must be first
require("UserConfigs.user-defaults")      -- locals: term, files, search engine
require("hyprflux-colors")                -- registers nothing; provides table via return

require("UserConfigs.user-settings")
require("UserConfigs.user-decorations")
require("UserConfigs.user-animations")

require("configs.keybinds")
require("UserConfigs.user-keybinds")
require("UserConfigs.laptops")
require("UserConfigs.window-rules")
require("UserConfigs.workspace-rules")

hl.on("hyprland.start", function()
    hl.exec_cmd(Home .. "/.config/hypr/initial-boot.sh")
end)
require("UserConfigs.startup-apps")

require("monitors")                       -- nwg-displays
require("workspaces")
```

## 15.3 Keybinds: count and plan (152 binds → ~100 lines)

| Source | Binds | Strategy |
|---|---|---|
| `configs/Keybinds.conf` | 93 | Loops for workspace group (30), literal for the rest |
| `UserConfigs/UserKeybinds.conf` | 46 | Literal; closures for parameterized script binds |
| `UserConfigs/Laptops.conf` | 13 | Literal + `hl.device` + per-device bind options |

Workspace loop (matches current keycode behavior — verify against `wev` keycodes):

```lua
local mainMod = "SUPER"
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mainMod .. " + " .. key,            hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,    hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. key,     hl.dsp.window.move({ workspace = "special:" .. tostring(i) }))
end
```

> Verify: current `Keybinds.conf` binds `SUPER, code:XX` for 1–0 — if the keycodes are `1..9,0`
> in order, `tostring(i % 10)` reproduces it exactly. If your layout differs (e.g. AZERTY),
> keep `code:` prefix binds.

Script-backed binds (UserKeybinds) — keep `hl.dsp.exec_cmd` with the full path:

```lua
local scripts = Home .. "/.config/hypr/scripts"
local userScripts = Home .. "/.config/hypr/UserScripts"

hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd(userScripts .. "/WallpaperSelect.sh"), { description = "Select wallpaper" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(scripts .. "/HyprFlux_Quick_Settings.sh"))
```

## 15.4 Window rules: order-preserving conversion

`WindowRules.conf` blocks convert 1:1 (doc 09 §9.2). Rules are grouped by tag — keep group order.
Two special cases:

1. **`windowrule-97`** (live machine): Playwright chromium → `workspace = "6 silent"` —
   `match = { class = "chromium-browser", title = ".*Chrome for Testing.*" }` — **note**: both
   props must match (AND). If the rule was two separate rules, keep them separate.
2. **Static effects on title-change** (float-on-title): convert to `hl.on("window.title", ...)`
   (doc 09 §9.4) — verify behavior matches.

## 15.5 nwg-displays / monitor profiles

- Keep `require("monitors")` + `require("workspaces")` in `hyprland.lua`.
- `modules/19-monitors.sh`: currently writes `monitors.conf` and overwrites
  `Monitor_Profiles/default.conf`. Update to write `monitors.lua` (+ keep `.conf` twin while
  legacy remains, guarded by a version check ≥0.55).
- `MonitorProfiles.sh`: copy/install `.lua` profiles instead of `.conf`.
- `nwg-displays` in `dotsSetup.sh`: ensure ≥ 2.4 (Lua-emitting).
- Do **not** set `misc.disable_autoreload = true` (nwg-displays warning).

## 15.6 Colors, decorations, animations

- `hyprflux-colors.lua` returns the palette; `user-decorations.lua` imports it
  (`active_border = colors.color12`, `inactive_border = colors.color10`).
- hyprlock/hypridle can't read Lua: keep the `.conf` palette duplicate if hyprlock references it.
- `user-animations.lua`: 7 curves + 9 animations (doc 11 §11.2). `animations/*.lua` presets
  converted; `Animations.sh` updated to swap `.lua` modules.

## 15.7 Script migration table (every `hyprctl` call in scripts)

| Script | Old call | New call |
|---|---|---|
| `Refresh.sh` / `RefreshNoWaybar.sh` | `hyprctl keyword ...` toggles | `hyprctl eval 'hl.config({...})'` or pure-Lua binds |
| `ChangeBlur.sh` | `hyprctl keyword decoration:blur:enabled` | `hyprctl eval 'hl.config({ decoration = { blur = { enabled = not hl.get_config("decoration.blur.enabled") } } })'` |
| `ChangeLayout.sh` | `hyprctl keyword general:layout` | `hyprctl eval 'hl.config({ general = { layout = "..." } })'` |
| `GameMode.sh` | multiple keywords | pure-Lua bind (doc 14 §14.4) |
| `Animations.sh` | copy animation conf + reload | copy `.lua` module + `hyprctl config full-reload` |
| `MonitorProfiles.sh` | install `.conf` profile | install `.lua` profile |
| `KeyHints.sh` / `KeyBinds.sh` | `hyprctl binds` | unchanged (still works) |
| `ScreenShot.sh` | `hyprctl dispatch exec` | `hyprctl eval 'hl.dsp.exec_cmd(...)'` (or keep dispatch — legacy OK) |
| `KillActiveProcess.sh` | `hyprctl dispatch killactive` | `hyprctl eval 'hl.dispatch(hl.dsp.window.close())'` |
| `SwitchKeyboardLayout.sh` | `hyprctl switchxkblayout` | keep (`hyprctl switchxkblayout` unchanged) |
| `Tak0-Autodispatch.sh` | socket2/`hyprctl` reads | optional: replace with `hl.on("window.active", ...)` (doc 14) |
| `Wlogout.sh` / `LockScreen.sh` | none | unchanged |

> `hyprctl dispatch` and `hyprctl keyword` still exist (legacy) — you can defer script rewrites
> to Phase 6, but they must be done before hyprlang is dropped since `keyword` maps to config
> semantics that no longer exist. Grep gate:
> `grep -rn "hyprctl keyword" scripts/ UserScripts/` and
> `grep -rn "hyprctl dispatch" scripts/ UserScripts/`.

## 15.8 Install/upgrade pipeline updates

- `dotsSetup.sh`: install `hyprland.lua`; stop installing `hyprland.conf`.
- `install.sh` / `modules/*`: replace any `hyprland.conf` reference; keep hyprlock/hypridle
  `.conf` installation.
- `v2.3.16` → bump to `v2.4.0` (dots version marker).
- README: update config-path references + wiki links (0.54 vs current).
- `.gitignore` unchanged (`.initial_startup_done` etc.).

## 15.9 What stays hyprlang (do NOT touch)

- `hyprlock.conf`, `hyprlock-1080p.conf` (hyprlock)
- `hypridle.conf` (hypridle)
- `application-style.conf` (hyprland-qt-support QML style)

## 15.10 Phase gates specific to HyprFlux

| Phase | Gate |
|---|---|
| 0 | `Hyprland --verify-config` green on old config; tag `v2.3.16`; backup |
| 1 | skeleton `--verify-config` green; LSP works; rollback rehearsed |
| 2 | `hyprctl getoption` spot-checks match; screenshots match |
| 3 | `hyprctl binds` == 152; matrix 13.3 all pass |
| 4 | rules spot-checks 13.4 pass; `hyprctl clients` correct |
| 5 | nwg-displays applies live; autostart identical; profiles Lua |
| 6 | grep gate clean; CI/verify wired; version bumped; PR merged |

Next: [16-troubleshooting-and-gotchas.md](16-troubleshooting-and-gotchas.md)
