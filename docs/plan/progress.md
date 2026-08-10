# Migration Progress Tracker

> Status of the HyprFlux hyprlang → Lua migration. One row per phase; gates from
> `04-migration-strategy.md` and `15-hyprflux-specific-plan.md`.

| Phase | Status | Date | Gates / notes |
|---|---|---|---|
| **0 — Prepare** | ✅ DONE | 2026-08-10 | Tagged `v2.3.16` baseline; backup at `~/.config/hypr.bak-hyprlang` (advised); inventory in doc 15 §15.1; `Hyprland --verify-config` green on old config; installed 0.56.2, stubs present. |
| **1 — Skeleton** | ✅ DONE | 2026-08-10 | `hyprland.lua` entrypoint created (not active); `UserConfigs/user-defaults.lua` + `hyprflux-colors.lua` converted; `.luarc.json` LSP wired; `luac -p` clean; `Hyprland --config ... --verify-config` → **config ok** (exit 0); rollback rehearsal passed (.conf parses when entrypoint removed; live machine has no `hyprland.lua` → boots .conf). |
| **2 — Settings/colors/env** | ✅ DONE | 2026-08-10 | Converted: `env-variables.lua` (incl. live GPU-pinning), `user-settings.lua`, `user-decorations.lua` (live border/colors), `user-animations.lua`; `user-defaults.lua` updated to live `term = kitty`. `--verify-config` green. |
| **3 — Keybinds** | ✅ DONE | 2026-08-10 | Converted: `configs/keybinds.lua` (93), `user-keybinds.lua` (46), `laptops.lua` (13 + `hl.device`). **152 binds** at runtime — exact parity with old config (verified via mock executor + live `hyprctl binds` = 152). Flags `bindel/bindl/binde/bindm` mapped per 0.54 wiki. Zoom binds converted to pure Lua. |
| **4 — Rules** | ✅ DONE | 2026-08-10 | Converted: `window-rules.lua` (97 rules incl. live rule 97 + 3 layer rules, order preserved, all named), `workspace-rules.lua` (guide), `workspaces.lua` (nwg-displays template). `--verify-config` green; rule count 97/3 verified. |
| **5 — Monitors/autostart** | ✅ DONE | 2026-08-10 | `startup-apps.lua` (11 execs via `hl.on("hyprland.start")`), `monitors.lua` + `workspaces.lua` wiring, `LaptopDisplay.lua` template, initial-boot moved into entrypoint handler. `modules/19-monitors.sh` dual-writes `.conf`+`.lua` + default profiles; `MonitorProfiles.sh` Lua-aware. `--verify-config` green; startup execs parity 11/11. |
| **6 — Refactor + ship** | ✅ DONE | 2026-08-10 | Runtime-toggle scripts re-pointed to `hyprctl eval` (ChangeBlur/GameMode/ChangeLayout/TouchPad); value-reading scripts now parse Lua modules (RofiSearch/SwitchKeyboardLayout/Tak0-Per-Window-Switch/HyprFlux_Quick_Settings); KeyBinds.sh reads live `hyprctl binds -j`; 16 animation presets converted to Lua (Animations.sh uses full-reload); legacy `.conf` moved to **`.config/hypr_old/`** (repo + live) per user decision; version bumped `v2.3.16` → `v2.4.0`; live flip staged — **session restart required to activate** (see note below). |

## Phase 1 artifacts (created)

```
.config/hypr/hyprland.lua                     — skeleton entrypoint (not active)
.config/hypr/UserConfigs/user-defaults.lua    — module: term/files/edit/search_engine
.config/hypr/hyprflux-colors.lua              — module: 17-color palette table
.luarc.json                                   — LSP wiring to /usr/share/hypr/stubs
```

## Phase 2+3 artifacts (created)

```
.config/hypr/UserConfigs/env-variables.lua    — hl.env (incl. live AQ_DRM_DEVICES/Mesa pinning)
.config/hypr/UserConfigs/user-settings.lua    — dwindle/master/input/gestures/misc/binds/xwayland/render/cursor/debug
.config/hypr/UserConfigs/user-decorations.lua — borders/gaps/decoration/group via colors module
.config/hypr/UserConfigs/user-animations.lua  — 7 curves + 10 animations
.config/hypr/configs/keybinds.lua             — 93 binds (workspace loop: 30 binds in 8 lines)
.config/hypr/UserConfigs/user-keybinds.lua    — 46 binds (zoom binds pure-Lua)
.config/hypr/UserConfigs/laptops.lua          — 13 binds + hl.device touchpad block
```

## Phase 4+5 artifacts (created)

```
.config/hypr/UserConfigs/window-rules.lua     — 97 window rules + 3 layer rules (order preserved, named)
.config/hypr/UserConfigs/workspace-rules.lua  — guide only (not required by default)
.config/hypr/UserConfigs/startup-apps.lua     — 11 exec-once via hl.on("hyprland.start")
.config/hypr/UserConfigs/LaptopDisplay.lua    — lid-close monitor template (replaces .conf)
.config/hypr/monitors.lua                     — nwg-displays template (fallback rule active)
.config/hypr/workspaces.lua                   — nwg-displays template (comments only)
modules/19-monitors.sh                        — dual-writes monitors.conf + monitors.lua + profiles
.config/hypr/scripts/MonitorProfiles.sh       — Lua-aware profile switcher (prefers .lua, falls back .conf)
```

## Findings from validation (0.56.2) — added to doc 16

1. `dwindle.*` / `master.*` are **flat config keys**, NOT nested under `layout.*`.
2. `hl.animation` **speed is capped at 100** (borderangle was 180 in hyprlang → now 100).
3. `XF86AudioPlayPause` is **not a valid keysym** in the Lua API (was accepted by hyprlang) →
   bound via `code:164` (KEY_PLAYPAUSE).

## Post-flip audit (2026-08-10) — .conf integration check

User reported SUPER+SHIFT+K (KeyBinds) and SUPER+SHIFT+E (Quick Settings) issues after the
flip. Root causes found and fixed, plus a full `.conf` integration audit:

| Item | Status |
|---|---|
| KeyBinds.sh python quoting (`' '.join` broke `python3 -c`) | FIXED — now `" ".join`; verified 152 formatted binds |
| HyprFlux_Quick_Settings.sh "view/edit" → deleted `.conf` files | FIXED — now points to Lua modules (`nvim` opened empty files before) |
| WaybarScripts.sh parsed `01-UserDefaults.conf` | FIXED — parses `user-defaults.lua` (term=kitty, files=thunar verified) |
| WallpaperSelect.sh wrote `Startup_Apps.conf` | FIXED — now seds `startup-apps.lua` (awww/mpvpaper/livewallpaper), tested |
| refresh-rate.sh `hyprctl keyword monitor` (live-only) | FIXED — `hyprctl eval 'hl.monitor({...})'` + fallback comment |
| Startup `livewallpaper` var | made active in `startup-apps.lua` (WallpaperSelect target) |
| Tak0-Autodispatch/ObsidianGenerate comments | updated hyprland.conf → hyprland.lua |
| Active `.conf` audit (hyprlock/hypridle/application-style/colors) | ✓ all internal `source=`/path refs resolve; hypridle running with hyprlang config; hyprlock-1080p palette source OK; wallpaper_effects paths OK |
| Lua ↔ .conf cross-references | ✓ only documentation comments; zero functional refs |
| Config parity on live Lua session | ✓ all options `set: true`; 152 binds; `hyprctl eval` works |
| Regenerated `hyprland.conf` stub | ✓ deleted; Lua session does not regenerate it |
| repo vs live trees | ✓ identical except intentional `refresh-rate.sh` (live-only) |

Remaining `.conf` files in the ACTIVE tree (by design, hyprlang tools):
`hyprlock.conf`, `hyprlock-1080p.conf` (sources `hyprflux-colors/hyprflux-colors.conf`),
`hypridle.conf`, `application-style.conf`. Everything else is archived in `.config/hypr_old/`.

## Animation preset bug round (2026-08-10) — SUPER+SHIFT+A error

User reported `user-animations.lua:22: hl.animation("borderangle"): unknown style` after
picking an animation preset. Root causes found and fixed:

| Bug | Fix |
|---|---|
| Converter emitted `style = "loop "` (trailing space) — the `[\w %]+` regex group swallowed the space before a `#comment` | converter now `style.strip()`s; all 17 presets regenerated from `hypr_old` sources |
| `01-default - v2` had `bezier("nice")` control points `6.9/-4.20` — out of the Lua API's `[-2, 2]` bounds → config load error | curve was **unused** by any animation → commented out |
| `hyprctl config full-reload` does **NOT exist on 0.56.2** ("unknown request") — Animations.sh and GameMode.sh used it | switched to `hyprctl reload` (verified working) |

**New validation gate added: every animation preset is `--verify-config`'d against the real
binary (17/17 PASS)** — previously only `luac -p` was run on presets. Live `user-animations.lua`
restored from the fixed preset (currently HYDE - default, the user's selection).

## Full system/user scripts audit (2026-08-10)

Comprehensive audit of all 46 system scripts + 19 user scripts + all Lua configs (syntax,
shebangs, exec bits, every referenced path):

| Finding | Status |
|---|---|
| `MediaCtrl.sh` — pre-existing syntax error `]]]` (breaks ALL media keys) + uninitialized `prev_status` | FIXED (`]]`, `prev_status` init) — media keys now actually work |
| `WallpaperAwww.sh` — tracked **non-executable** in git (100644) → wallpaper flows fail on install | FIXED `chmod +x` (repo + live) |
| `Tak0-Per-Window-Switch.sh` — missing shebang | FIXED (`#!/bin/bash` + exec bit) |
| `RofiEmoji.sh` — `bash -n` fails on emoji data lines | FALSE POSITIVE — self-extracting data after `exit`, runtime-verified working |
| `MonitorProfiles.sh` — legacy `.conf`-only profile would copy but never apply in Lua mode | FIXED — transparent warning notification; `.lua` preferred |
| Path audit (every `$HOME/.config/hypr/...` ref in 65 scripts + all Lua) | ✓ only intentional refs remain (`monitors.conf` legacy fallback + runtime `.weather_cache`) |
| External configs (rofi themes, swaync images/icons, waybar, quickshell, hyprlock fonts) | ✓ all present |
| Python scripts | ✓ `Weather.py` compiles |
| Exec bits | ✓ all set |

## Decision (2026-08-10) — remaining .conf files

Confirmed with the user: the 5 `.conf` files left in the active `hypr` folder are **required and
must NOT be deleted** — they belong to hyprlang-only tools (officially never converted to Lua):

- `hyprlock.conf`, `hyprlock-1080p.conf` → hyprlock (lock screen)
- `hypridle.conf` → hypridle (idle daemon)
- `application-style.conf` → hyprland-qt-support QML style
- `hyprflux-colors/hyprflux-colors.conf` → palette sourced by `hyprlock-1080p.conf`

All obsolete compositor `.conf` files are archived in `.config/hypr_old/` (both repo and live).

## Single color source — second pass (2026-08-10)

Redone per user request with the lesson from the first attempt: **values are preserved
verbatim per app** (only their LOCATION changed), so no app changes appearance.

`hyprflux-colors/hyprflux-colors.conf` now holds **146 color variables** in named sections:
CORE UI, LOCK (hyprlock), TERMINAL ANSI (kitty/foot), NAVBAR (catppuccin mocha + preset
extras), NOTIF (swaync), LOGOUT (wlogout), ROFI (rasi + master-config), QUICKSHELL
(qml_color.json + Appearance/widget fallbacks).

`utilities/sync-colors.sh` regenerates: hyprflux-colors.lua, rofi/wallust/hyprflux-colors.rasi,
waybar/hyprflux-colors.css, kitty/kitty-colors.conf, foot/colors.ini, quickshell/qml_color.json,
and patches Appearance.qml + widget fallbacks.

All consumers reference vars: kitty.conf → include, foot.ini → include, swaync/wlogout → @import,
waybar presets → @import (catppuccin names defined in palette css with identical values),
master-config.rasi → @vars, hyprlock → $vars, DarkLight.sh → targets palette files.

**Verified:** 0 hardcoded colors in any config (remaining hits are generated fallbacks with
palette values); looks preserved; rofi/kitty/foot/lua/json/verify-config all pass; repo↔live
consistent.

### SwayNC fix (2026-08-10)

User reported swaync notification center transparent + white borders after the centralized
colors refactor. Root cause: swaync parses CSS with **GTK4**, and `@define-color` from
`@import`'d files does not reliably propagate — plus my refactor left self-referential
defines (`@define-color noti-bg @noti-bg;`). All `@vars` were undefined → GTK fell back to
defaults (transparent bg, white cards).

Fix: swaync + wlogout no longer `@import` the palette css. `sync-colors.sh` now **injects a
self-contained generated `@define-color` block** directly into both files (marker-delimited,
idempotent). All values still come from `hyprflux-colors.conf`. Verified: single block,
all vars defined, swaync reloads clean, journal has zero CSS errors.

### Notification icons → Papirus themed (2026-08-10)

Per user request: replaced all custom notification icon images (`swaync/images/*.png`,
`swaync/icons/*.png`) used by scripts with **Papirus icon names** (resolved via the installed
Papirus-Dark theme through GTK).

Mapping: ja.png→dialog-information, error.png→dialog-error, note.png→text-x-generic,
bell.png→preferences-system-notifications, music.png→audio-x-generic, volume-*.png→
audio-volume-{high,medium,low,muted}, microphone*.png→audio-input-microphone(-muted),
brightness-*.png→display-brightness, timer.png→alarm-clock, picture.png→image-x-generic.

27 scripts + `hypridle.conf` updated; dead `iDIR`/`notif`/`IDIR`/`iDoR` definitions removed.
Verified: zero `swaync/images|icons` references in the active config (only `hypr_old` archive +
chromium cache); all scripts pass `bash -n` (RofiEmoji excluded — self-extracting data);
test notifications sent with themed icons.

## Status

- **Live session: RUNNING THE LUA CONFIG** (verified: `dispatcher: __lua`, 152 binds, all
  options `set: true`, `hyprctl eval` works).
- The two reported keybind issues (SUPER+SHIFT+K, SUPER+SHIFT+E) are fixed on live — please
  re-test them.
- Rollback (if ever needed): `cp ~/.config/hypr_old/hyprland.conf ~/.config/hypr/` and remove
  `hyprland.lua` (precedence is checked once at startup).
- Remaining work: run the on-session test matrix (doc 13 §13.3) after the script fixes; commit
  the migration when happy with it.
