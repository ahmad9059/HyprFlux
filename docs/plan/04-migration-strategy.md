# 04 — Migration Strategy (7-Phase Plan)

This is the *how*. It is designed so that **Hyprland never stops working** during the migration:
the legacy `.conf` keeps loading until the very last commit swaps the entrypoint, and every phase
is independently verifiable.

## 4.1 Guiding principles

1. **One entrypoint flip, everything else parallel.** Convert modules first; only the last step
   replaces `hyprland.conf` with `hyprland.lua`. Until then, old config keeps running.
2. **Convert, don't rewrite.** 1:1 translation first (binds, rules, settings), then *refactor* to
   idiomatic Lua (loops, closures) in a separate step with behavior-diff.
3. **Machine-checked, not eyeballed.** `Hyprland --verify-config` + `luac -p` + LSP stubs at
   every phase boundary.
4. **Scripts are part of the config.** ~30 HyprFlux scripts call `hyprctl dispatch` /
   `hyprctl keyword` — they must be re-pointed (doc 15 §7) or they break behavior silently.
5. **Green/blue deployment via git.** Every phase = a branch; `hyprland.lua` vs `hyprland.conf`
   entrypoint = instant rollback.

## 4.2 The 7 phases

```
Phase 0  Prepare          (0.5 day)
Phase 1  Skeleton         (0.5 day)
Phase 2  Settings+colors  (1 day)
Phase 3  Keybinds         (2 days)   ← biggest chunk (152 binds)
Phase 4  Rules            (1 day)    ← 96 window rules + 3 layer rules
Phase 5  Monitors/autostart (1 day)
Phase 6  Refactor+ship    (2 days)
```

Total: **~1 week** of focused work, or 2–3 weeks part-time. Each phase ends with a *done* gate
defined below.

---

## Phase 0 — Prepare (0.5 day)

Goals: freeze state, create workspace, baseline metrics.

- [ ] `hyprctl version` → confirm ≥ 0.55 (HyprFlux target: 0.56.2).
- [ ] `git tag` current dots version (`v2.3.16`) — the rollback point.
- [ ] Full backup: `cp -a ~/.config/hypr ~/.config/hypr.bak-hyprlang`.
- [ ] `git branch migration/lua` off main.
- [ ] Baseline inventory (already done in doc 15 §1):
      - 152 active binds across 3 files
      - 96 `windowrule` blocks + 3 `layerrule` blocks
      - 16 animation presets, 9 animations active
      - 9 `exec-once`, ~23 `env`, 1 `device` block, 1 `gestures` block
- [ ] Baseline verification: `Hyprland --verify-config` exits 0 with the *old* config.
- [ ] Check installed stubs: `ls /usr/share/hypr/stubs/` (present).
- [ ] Grep configs for removed options (doc 16 §16.2): `workspace_swipe`, `pseudotile`,
      `ignore_window`, `cm_fs_passthrough`, `misc:vfr`.
- [ ] Check plugin sections (`plugin { }`) — none in HyprFlux core; verify at runtime.

**Gate:** old config verified; backup exists; inventory table complete.

## Phase 1 — Skeleton (0.5 day)

Goals: prove the loading mechanism end-to-end with *no* behavior change.

- [ ] Create `hyprland.lua` (new entrypoint, not yet active) containing only:
      ```lua
      local Home = os.getenv("HOME")
      require("configs/Keybinds")          -- Phase 3
      require("UserConfigs/01-UserDefaults") -- Phase 2
      ```
- [ ] Convert the two *smallest* files to prove patterns (e.g. `01-UserDefaults.conf`,
      `hyprflux-colors.conf`).
- [ ] `Hyprland --config ~/.config/hypr/hyprland.lua --verify-config` — headless validation of the
      skeleton against the real binary.
- [ ] Set up `.luarc.json` LSP (doc 03 §3.8).
- [ ] Practice a rollback: delete `hyprland.lua`, confirm `.conf` boot still works.

**Gate:** skeleton verifies headlessly; rollback rehearsal passed.

## Phase 2 — Settings, colors, environment (1 day)

Goals: `hl.config()` categories, color module, env vars — no visual behavior change.

- [ ] `hyprflux-colors.conf` → `hyprflux-colors.lua` (returns table; doc 06 §6.4).
- [ ] `UserSettings.conf` → `user-settings.lua` (dwindle/master, input, gestures, misc, binds,
      xwayland, render, cursor, debug; doc 06 §6.3). Watch: `kb_options`, `vrr`, `swallow`.
- [ ] `UserDecorations.conf` → `user-decorations.lua` (general border/gaps, decoration, group).
- [ ] `ENVariables.conf` → `env-variables.lua` (`hl.env`, doc 10). Live-machine additions
      (`AQ_DRM_DEVICES`, Mesa pinning, `HYPRCURSOR_SIZE=24`) must be preserved.
- [ ] `UserAnimations.conf` → `user-animations.lua` (curves + animations; doc 11).
- [ ] A/B: boot with `--config` pointing to a **hybrid** config (`hyprland.lua` + keep old
      `hyprland.conf` for binds/rules) — visuals identical to old.
- [ ] Screenshot-diff wallpapers/borders/gaps before vs after.

**Gate:** no visual/behavioral diff; `--verify-config` clean; runtime toggles in REPL work.

## Phase 3 — Keybinds (2 days) — the big one

Goals: all 152 binds functional, with keybinds first as *translation*, then loops.

- [ ] Convert `configs/Keybinds.conf` (93 binds) → `configs/keybinds.lua`:
      table-driven loops for workspace binds (doc 07 §7.7), literal binds elsewhere.
- [ ] Convert `UserConfigs/UserKeybinds.conf` (46 binds) → `user-keybinds.lua`.
- [ ] Convert `UserConfigs/Laptops.conf` (13 binds + `device:` block + `$Touchpad_Device`) →
      `laptops.lua` (`hl.device` + per-device binds; doc 07 §7.10).
- [ ] Convert all `bindl`/`bindr`/`binds`/`bindm` variants to flag tables (doc 07 §7.4).
- [ ] Submaps: `UserKeybinds.conf`/`Laptops.conf` use `bind` + manual submap via scripts — check
      for `submap` dispatches in `Keybinds.conf`; convert with `hl.define_submap` (doc 07 §7.9).
- [ ] **Bind-test every single one** against the test matrix (doc 13 §13.3). 152 binds — no
      exceptions.
- [ ] Verify no phantom binds: `hyprctl binds` output diff (names + count) vs old config.

**Gate:** `hyprctl binds` count identical; 100% binds tested; no latency regression
(binds must be *faster* — direct dispatch vs spawned process).

## Phase 4 — Rules (1 day)

Goals: 96 window rules + 3 layer rules + workspace rules, same precedence.

- [ ] Convert `WindowRules.conf` blocks → `window-rules.lua` (doc 09). Preserve **order** —
      precedence is top-to-bottom, named-first.
- [ ] Convert the 3 `layerrule`s (rofi blur, notifications, quickshell) → `hl.layer_rule`.
- [ ] Convert `workspaces.conf`/`WorkSpaceRules` guide → `workspaces.lua` (doc 08).
- [ ] Convert `monitors.conf`-style rules only if nwg-displays doesn't manage them; else leave
      to Phase 5.
- [ ] Spot-check with targeted apps (browser→ws2, thunar→ws3, steam→ws5, virt-manager→ws9,
      obsidian→ws10, playwright chromium rule, pinentry float) — the doc-15 test list.

**Gate:** every tagged app lands where the old config put it; layer blur identical.

## Phase 5 — Monitors, workspaces, autostart (1 day)

Goals: nwg-displays integration, exec-once, env.

- [ ] `Startup_Apps.conf` (9 exec-once) → `startup-apps.lua` with `hl.on("hyprland.start")`.
- [ ] `monitors.lua` wiring: `require("monitors")` — nwg-displays 2.4+ already emits it.
      Keep `monitors.conf` generation for legacy until final flip (dual-write).
- [ ] `workspaces.lua` wiring.
- [ ] Update `modules/19-monitors.sh` to write/expect `.lua` (doc 15 §5).
- [ ] Update `nwg-displays` docs/README in repo if referenced.
- [ ] Convert `hyprland.conf`'s own `exec-once` (initial-boot.sh) into `hyprland.lua`.
- [ ] `refresh-rate.sh` service stays (systemd), no config change needed.

**Gate:** hotplug monitors work; autostart identical; nwg-displays writes apply live.

## Phase 6 — Refactor, polish, ship (2 days)

Goals: idiomatic Lua, cleanup, release.

- [ ] Refactor translation → idiomatic: loops (doc 07 §7.7), closures (doc 14), conditional
      keybinds (`hyprctl clients`-style guards, doc 14 §14.5), `hl.on` events where they replace
      scripts (e.g. gamemode, wallpaper events).
- [ ] Move runtime-toggle scripts (Refresh.sh toggles blur/gaps/animations) into `hl.config()`
      calls via `hyprctl eval` or pure-Lua binds (doc 14).
- [ ] Update `dotsSetup.sh` + `install.sh` + `modules/*` that install/source `.conf`.
- [ ] Rewrite `hyprland.conf` → `hyprland.lua`; delete legacy files; bump dots version.
- [ ] CI gate (optional): run `Hyprland --verify-config` + `luac -p` on every dotfile commit.
- [ ] Update `README.md` links/docs; release.

**Gate:** no `.conf` referenced anywhere except hyprlock/hypridle/application-style; verify passes;
clean `git status`.

## 4.3 Risk matrix

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Behavior drift (binds/rules not identical) | High | Medium | Per-phase `hyprctl binds` diff; test matrix; keep old config until final flip |
| `hyprlang` dropped mid-migration | Medium | High | Finish before 0.57; both formats work now |
| Scripts using old `hyprctl dispatch` syntax | High | Medium | doc 15 §7 migration table; `hyprctl eval` equivalents |
| Blocking keybind callback freezes desktop | Medium | High | Code-review rule (doc 14 §14.8); `hl.dsp.exec_cmd` everywhere |
| LSP/stub drift (API moved between 0.55–0.56) | Medium | Low | Pin stubs to installed version; `--verify-config` gate |
| `$VAR` not expanded → bad paths | High | Medium | Grep for `$` in all converted strings; `os.getenv` pattern |
| Plugin config sections break | Low (none used) | High | Check `hl.plugin.*` before enabling plugins |
| nwg-displays overwrites user edits (as before) | High | Low | Same as today: keep user edits in UserConfigs, generated in root |

## 4.4 Suggested git workflow

```
main
 └── migration/lua            ← all phase commits
      ├── phase1-skeleton
      ├── phase2-settings
      ├── phase3-keybinds
      ├── phase4-rules
      ├── phase5-monitors-autostart
      └── phase6-refactor-ship   ← merge to main, tag v2.4.0
```

Rollback = checkout the tag before the flip commit. No force-pushes; the old config stays in the
repo history for reference (keep `WindowRules-old.conf`-style files as `*-hyprlang.bak` only if
wanted — prefer git history).

Next: [05-hyprlang-to-lua-mapping.md](05-hyprlang-to-lua-mapping.md)
