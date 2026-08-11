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

### Brightness fix (2026-08-10)

User reported: Fn+F7/F8 brightness — when it hits 100%, pressing up drops the brightness a lot.
The script's math was verified correct (clamps at max, no wrap). The drop is hardware/kernel
level — two suspects:

1. **AMD eDP quirk**: setting exactly 100% (65535) on some panels makes the screen go very dark.
   → **FIXED in Brightness.sh**: brightness is now capped at **95%** (MAX=95, MIN=5), plus a
   robust percent fallback if the `brightnessctl -m` parse ever fails. Verified: 90→95, stays
   95 on repeat, dec→85.
2. **Kernel double-handling**: `/sys/module/video/parameters/brightness_switch_enabled = Y` and
   `asus_nb_wmi` is loaded — the kernel may also adjust/wrap the backlight on the same keys.
   If the drop persists after the 95% cap, run (user, with password):
   `sudo sh -c 'echo 0 > /sys/module/video/parameters/brightness_switch_enabled'`
   and make permanent by adding `video.brightness_switch_enabled=0` to
   `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub` + `sudo grub-mkconfig -o /boot/grub/grub.cfg`.

### hyprctl dispatch legacy syntax broke (2026-08-10)

User reported waybar workspace clicks stopped switching. Root cause: in Lua mode,
**`hyprctl dispatch <old-hyprlang-string>` no longer works** — hyprctl parses the argument as
Lua (`hl.dispatch(workspace 2)` → syntax error). Waybar's `"activate"` action and its
`hyprctl dispatch workspace e+1` scroll actions used the old strings.

Fixed everywhere (verified `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'` etc. work):

- **waybar `ModulesWorkspaces`** (all 6 variants): on-click → `hyprctl dispatch hl.dsp.focus({ workspace = $WORKSPACE_ID })`, scroll → `hl.dsp.focus({ workspace = "e+1"/"e-1" })`
- **waybar `ModulesCustom`**: quit button → `hyprctl dispatch hl.dsp.exit()`
- **`Dropterminal.sh`** (16 calls): movewindowpixel/pin/movetoworkspacesilent/resizewindowpixel/focuswindow/exec-with-rules → `hyprctl eval "hl.dispatch(hl.dsp.window.move/pin/resize/focus(...))"` and `hl.exec_cmd(cmd, rules)`
- **`Tak0-Autodispatch.sh`** (2 copies): workspace/movetoworkspace → Lua forms
- **`hypridle.conf`**: dpms on/off → `hl.dsp.dpms({ action = "on"/"off" })`
- **`user-keybinds.lua`** SUPER+ALT+SPACE "All Float": `workspaceopt allfloat` is unreachable
  from Lua (not in `hl.dsp`) → implemented natively (iterate windows, toggle float by
  `hl.get_workspace_windows` + `hl.dsp.window.float({ action })`)
- keybinds.lua splitratio comment updated

### Waybar workspace clicks still broken — root cause (2026-08-10)

After the dispatch-syntax fixes, clicks STILL didn't switch. Investigated waybar's source
(`src/modules/hyprland/workspace.cpp`): `Workspace::handleClicked()` **ignores the `on-click`
config entirely** and always sends the legacy `IPC::dispatch("workspace", N)` /
`togglespecialworkspace` strings over the IPC socket — which fail in Lua mode.

Upstream fix: **Waybar PR #5013** ("adapt dispatch commands for Lua IPC protocol", merged
2026-05-04) — adds protocol auto-detection and maps to `/dispatch hl.dsp.focus({ workspace = "N" })`
etc. It is **NOT in 0.15.0** (released 2026-02-06, before the fix) — confirmed: the installed
binary contains zero `hl.dsp` strings.

**Fix for the user:** install `waybar-git` (already available from **chaotic-aur**):
`sudo pacman -S waybar-git` → restart waybar. No config workaround exists for 0.15.0 clicks.
(The on-click/scroll Lua-form config stays — correct for the fixed versions.)

✅ **CONFIRMED FIXED (2026-08-10):** after installing `waybar-git`, workspace clicks work.

### ags / quickshell fully removed (2026-08-10)

Per user request, quickshell (and ags remnants) removed entirely:

- **Configs**: `.config/quickshell/` deleted (repo + live); no ags config existed
- **Hyprland Lua**: `startup-apps.lua` (`hl.exec_cmd("qs")`), `user-keybinds.lua` (SUPER+A
  overview bind incl. commented ags variant), `window-rules.lua` (quickshell:overview layerrule)
- **Scripts**: Refresh.sh/RefreshNoWaybar.sh (ags/qs restart blocks + pid lists), KeyHints.sh
  (overview line), DarkLight.sh (whole ags color block + ags in pid lists)
- **Colors**: `$qs_*` section removed from hyprflux-colors.conf; quickshell sections removed
  from sync-colors.sh (qml_color.json + Appearance/widgets patches); regenerated
- **Install pipeline**: `modules/15-quickshell.sh` deleted; quickshell/ags refs removed from
  `scripts/initial.sh`, `scripts/bypass_dialogs.sh`, `scripts/replace_reads.sh`
- **Live**: `qs` process stopped, `~/.config/quickshell` deleted, config reloaded
- **Package** (user): `sudo pacman -Rns quickshell`
- Verified: zero quickshell/ags/qs references in repo + live; `config ok`; repo↔live consistent

### GameMode.sh rewritten (2026-08-10)

User reported toggling game mode off didn't revert. Two bugs: (1) the toggle detection compared
`hyprctl getoption animations:enabled` output (`bool: true`) against `1` — never matched, so the
enable branch never ran; (2) the disable path relied on `hyprctl reload` instead of restoring the
actual previous values (and a runtime window-rule that may persist across reloads).

New design — a proper state-based toggle:

- State file `$XDG_RUNTIME_DIR/gamemode.state` decides the branch (like TouchPad.sh)
- **Enable** saves the exact current values (gaps/border/rounding/blur/shadow/animations/
  opacities) then applies game values; opacity handled via `hl.config` (no window rule)
- **Disable** restores every saved value from the state file — manual tweaks (ChangeBlur etc.)
  survive; no reload needed
- Verified round-trip: 2/4/2/10/true/false/true/0.9 restored exactly; state file removed

### Removed 7 scripts + all their functionality (2026-08-10)

Per user request, removed (repo + live, all references cleaned so nothing breaks):

| Script | Removed from |
|---|---|
| `Polkit-NixOS.sh` | startup-apps.lua comment |
| `DarkLight.sh` | waybar `custom/light_dark` on-click + tooltip (module kept for WaybarStyles/WallpaperSelect), Quick Settings menu item |
| `UptimeNixOS.sh` | hyprlock-1080p.conf uptime fallback (`uptime -p` only now) |
| `RofiThemeSelector.sh` + `-modified.sh` | Quick Settings menu item, keybinds comments |
| `Kitty_themes.sh` | Quick Settings menu item |
| `ZshChangeTheme.sh` (UserScripts) | SUPER+SHIFT+Z bind |

Verified: zero references in repo + live; `config ok`; scripts syntax OK; waybar running.
NOTE: Dark/Light wallpaper dirs (`Pictures/wallpapers/Dynamic-Wallpapers/*`) left untouched.

### Removed sddm_wallpaper.sh.bak + Jellyfin.sh (2026-08-10)

- `scripts/sddm_wallpaper.sh.bak` — dead backup; also removed the SDDM "offer" tail blocks in
  `WallpaperEffects.sh` (called the missing `sddm_wallpaper.sh --effects`) and the
  `set_sddm_wallpaper` call + commented function in `WallpaperSelect.sh`
- `UserScripts/Jellyfin.sh` — `SUPER+SHIFT+J` bind removed from user-keybinds.lua
- Verified: zero refs in repo + live; scripts/Lua syntax OK; `config ok`; repo↔live consistent

### Window rules reorganization (2026-08-10)

Applied per user-reviewed plan:

- **ws 1 (Dev)**: VSCode now routes there — `code` class added to projects tags (rules 15/16;
  previously VSCode never matched); Chrome for Testing (Playwright) moved 6→**1 silent** (dev tool)
- **ws 2 (Browser)**: chromium now tagged `+browser` (rule 47, keeps `tile = true`) → routes to 2
- **Terminal**: `foot` added to `+terminal` tag (rule 12); **kitty/terminals are workspace-free**
  (only kitty+tmuxifier → 1)
- **ws 6 (Games)**: gamestore (rule 66) + games (rule 67, fullscreen/no-blur) **merged into 6**
- **Media freed**: rule 74 (multimedia → 9 silent) **removed** — mpv/vlc/audacious open anywhere
- **ws 5** now free (was gamestore); **Spotify stays in `special:nyx`** (unchanged)
- No utilities/viewer workspace routing added

Final map: 1=dev/email, 2=browser, 3=files, 4=IM+screenshare, 6=games, 9=VMs, 10=obsidian,
special:nyx=chat; media & terminals free.

## Improvement batch applied (2026-08-10) — 16 items

**Cleanup:** deleted 28 unused swaync images/icons + dirs; removed duplicate
`scripts/Tak0-Autodispatch.sh` (UserScripts copy authoritative); removed dead `swallow_regex`;
modules renumbered 01–18 (15-quickshell gap closed, `bypass_dialogs` verified consistent).

**Bugs:** Weather.py rewritten on **wttr.in** (stdlib only, no scraping/pyquery — was broken by
weather.com markup change; waybar JSON + hyprlock cache preserved); GameMode disable no longer
runs Refresh.sh (instant toggle); refresh-rate `hl.monitor` eval path **verified live**
(60↔165 Hz round-trip OK).

**Performance:** borderangle animation `loop`→`once`; `render.direct_scanout` 0→2 (auto);
`decoration.blur.special` true→false (kept popups).

**Automation:** `.github/workflows/config-check.yml` (arch container: luac all Lua +
`Hyprland --verify-config` + `sync-colors.sh` up-to-date gate, runs on config PRs/pushes);
Quick Settings gains "Check for HyprFlux Updates".

**Architecture:** KeyHints.sh now generates LIVE from `hyprctl binds -j` (stale entries like
"Change Zsh theme"/"Mount Google Drive" gone automatically); `hyprland.lua` phase-comments
cleaned; UserScripts `00-Readme` documents the duplication policy (UserScripts wins).

All validated (`config ok`, luac, bash -n, py_compile), synced to live, Hyprland reloaded.

### KeyHints.sh rebuilt — curated from the real config (2026-08-10)

The `hyprctl binds -j`-generated version showed wrong/incomplete keys. Rebuilt as a **curated
cheat sheet** directly from the actual binds (configs/keybinds.lua + user-keybinds.lua +
laptops.lua): 101 key/description pairs grouped into Apps / Windows / Workspaces / Screenshots /
Media & Hardware / Features. Every listed bind was verified against the config files
(`RETURN` casing matched, commented binds excluded, XF86/arrow/wheel groups validated).

## Status

- **Live session: RUNNING THE LUA CONFIG** (verified: `dispatcher: __lua`, 152 binds, all
  options `set: true`, `hyprctl eval` works).
- The two reported keybind issues (SUPER+SHIFT+K, SUPER+SHIFT+E) are fixed on live — please
  re-test them.
- Rollback (if ever needed): `cp ~/.config/hypr_old/hyprland.conf ~/.config/hypr/` and remove
  `hyprland.lua` (precedence is checked once at startup).
- Remaining work: run the on-session test matrix (doc 13 §13.3) after the script fixes; commit
  the migration when happy with it.
