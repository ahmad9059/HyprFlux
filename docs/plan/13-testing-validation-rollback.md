# 13 — Testing, Validation and Rollback

The migration touches 115+ files and every keypress of your daily driver. This is the testing
protocol that makes that safe.

## 13.1 Principles

1. **The old config stays live until the flip.** Phases 1–5 run in parallel: you boot with
   `hyprland.conf`, and validate the Lua side headlessly (`--verify-config`) plus on-demand
   (`Hyprland --config ...` on a TTY or test session).
2. **Per-phase gates** (doc 04): don't start Phase N+1 until Phase N's gate is green.
3. **Diff, don't eyeball.** `hyprctl binds` counts, `hyprctl getoption` values, screenshots.
4. **Test on the real session** — but have the rollback one command away.

## 13.2 Test sessions

| Method | When | How |
|---|---|---|
| `Hyprland --verify-config` | every edit | headless parse+apply check |
| `luac -p` | every edit | syntax |
| TTY test session | per-phase | on a second VT (Ctrl+Alt+F3): `Hyprland --config ~/.config/hypr/hyprland.lua` — requires a free session; keep binds minimal during skeleton phase |
| Live session (daily driver) | after Phase 2+ | flip entrypoint, use the desktop for a day, fix regressions |
| `hyprctl repl` | during work | test snippets against live state without editing config |

For a full dual-boot style test without touching your session: use a different
`XDG_CONFIG_HOME` or `--config` path with a copy of the tree.

## 13.3 Bind test matrix (all 152)

Before flipping, test every bind class (not every key — the matrix covers variants):

| # | Class | Spot-test | Expect |
|---|---|---|---|
| 1 | Workspace switch 1–10 | SUPER+1 … SUPER+0 | each workspace opens |
| 2 | Move to workspace | SUPER+SHIFT+1..0 | window moves |
| 3 | Special/scratchpad | SUPER+CTRL+1, SUPER+S | toggles special |
| 4 | Apps | SUPER+D, SUPER+RETURN, SUPER+F | correct app |
| 5 | Window ops | SUPER+V(float), SUPER+F(fs), SUPER+P | toggles |
| 6 | Mouse binds | SUPER+LMB/RMB | drag/resize |
| 7 | Media/vol/brightness (locked+repeating) | XF86 keys | works on lockscreen |
| 8 | Screenshots | Print, SUPER+F6 | correct script |
| 9 | Laptop keys | XF86Brightness*, touchpad toggle | works |
| 10 | Submaps | ALT+R resize, escape exit | exits submap |
| 11 | Scripts-as-binds | SHIFT+W wallpaper, SHIFT+G gamemode | scripts run |
| 12 | Lock/exit | SUPER+L, logout | session ends cleanly |

Automation: script `hyprctl dispatch` equivalents of the pure-dispatcher binds (or `hyprctl eval
'hl.dispatch(...)'`) and diff results. Manually test app/script binds.

## 13.4 Rule spot-checks (96 rules)

| Window | Expect |
|---|---|
| firefox/chromium | workspace 2 |
| thunar | workspace 3, float+center per rule |
| steam | workspace 5 |
| discord / screenshare | workspace 4 |
| virt-manager | workspace 9 |
| obsidian | workspace 10 |
| pinentry | float + stay_focused |
| rofi | layerrule blur |
| swaync notifications | layerrule blur |
| quickshell overview | layerrule no_anim |
| Playwright chromium (`.*Chrome for Testing.*`) | workspace 6 silent (live-machine rule 97) |

Check with `hyprctl clients` (workspace/float state) and `hyprctl layers`.

## 13.5 Visual regression

- Screenshot before/after: borders (`border_size` + colors), gaps (2/4), rounding (10), blur
  (size 6, passes 2), dim_inactive, group colors, animations (slow-mo video or
  `animations` toggle).
- `hyprctl getoption` dumps for: `general:*`, `decoration:*`, `group:*`, `input:*`, `misc:vrr`,
  `misc:swallow*`, `xwayland:force_zero_scaling`.

## 13.6 Rollback

**Until the final flip:** rollback = delete/ignore `hyprland.lua`; `.conf` boots unchanged.

**After the flip:** rollback = checkout the pre-flip tag:

```bash
git checkout v2.3.16           # pre-Lua dots version
dotsSetup.sh --restore         # per repo tooling; or:
cp -a ~/.config/hypr.bak-hyprlang/. ~/.config/hypr/
```

Keep the `.bak-hyprlang` backup until the migration has survived a week of daily use + one full
`pacman -Syu` + one monitor hotplug cycle.

**Emergency during a session:** if a runtime Lua error breaks your desktop before binds load,
use the emergency binds Hyprland injects (SUPER+Q / R / M = terminal, run, exit). If input is
completely frozen (blocking callback), kill the session from a TTY:
`loginctl terminate-session $XDG_SESSION_ID` (hyprland will restart with last-good config if
you restored it; otherwise boot to TTY, restore backup, `exec Hyprland`).

## 13.7 Regression scenarios (beyond the happy path)

- [ ] Reboot (config precedence re-checked at startup)
- [ ] Lock screen + unlock (locked binds still work; hyprlock hyprlang untouched)
- [ ] Laptop lid close/open (`LaptopDisplay.lua` monitor rule + switch binds)
- [ ] Monitor hotplug (nwg-displays writes `monitors.lua` → applies without reload)
- [ ] Battery/AC change (refresh-rate service unaffected)
- [ ] Suspend/resume (hypridle still hyprlang)
- [ ] `hyprctl reload` mid-session (Lua reloads cleanly; `package.path` intact on 0.56.1+)
- [ ] GPU switching (AQ_DRM_DEVICES env preserved in Lua)
- [ ] Second session (TTY) — config loads, emergency binds if errors

## 13.8 Sign-off checklist (final)

- [ ] `luac -p` + `Hyprland --verify-config` green
- [ ] `hyprctl binds` count == 152 (or deliberate diff documented)
- [ ] Bind test matrix 100%
- [ ] Rule spot-checks 100%
- [ ] Visual diff clean
- [ ] All scripts re-pointed (doc 15 §7) — grep for `hyprctl dispatch`/`keyword` in `scripts/`
- [ ] nwg-displays writes Lua; profiles work
- [ ] No `.conf` files referenced except hyprlock/hypridle/application-style
- [ ] One week of daily use with zero rollback

Next: [14-advanced-lua-patterns.md](14-advanced-lua-patterns.md)
