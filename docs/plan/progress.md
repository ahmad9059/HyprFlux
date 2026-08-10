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

## Next action

**ACTIVATE THE FLIP on the live machine: restart the session** (logout/login or reboot).
Until then the running session still uses the old in-memory config. After restart:

- `~/.config/hypr/hyprland.lua` becomes the boot config (Lua takes precedence over `.conf`).
- Run the on-session test matrix (doc 13 §13.3) + rule spot-checks (doc 13 §13.4).
- Delete the regenerated `~/.config/hypr/hyprland.conf` stub if present (the old running
  session re-creates it because its config was removed; it is never loaded by the Lua session).
- Rollback (if ever needed): `cp ~/.config/hypr_old/hyprland.conf ~/.config/hypr/` and remove
  `hyprland.lua` (precedence is checked once at startup).
