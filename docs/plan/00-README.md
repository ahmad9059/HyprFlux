# HyprFlux — Hyprland Lua Migration Plan

**Status:** Planning · **Target Hyprland:** 0.56.2 (installed) · **Config format:** hyprlang (`.conf`) → Lua (`hyprland.lua`)

> Since Hyprland **0.55**, the hyprlang config syntax (`.conf` files) is **deprecated in favor of Lua**.
> The compositor config now lives at `~/.config/hypr/hyprland.lua`. Hyprlock, Hypridle and
> other `hypr*` tools **keep hyprlang** — only the compositor moved.
>
> — [Hyprland wiki, Configuring/Start](https://wiki.hypr.land/Configuring/Start/)

This folder is the complete, step-by-step migration plan for **HyprFlux** (this repo) to move its
Hyprland dotfiles from hyprlang to Lua. It was written from the official Hyprland wiki
(hyprland-wiki `main`), the Hyprland 0.55/0.56 release notes, the example `hyprland.lua`, and
community migration reports (Reddit, GitHub issues, converter projects).

---

## Why this migration is urgent

| Version | What happens |
|---|---|
| 0.55.0 (2026-05-09) | Lua configs supported. `.conf` still loaded if no `hyprland.lua` exists. |
| 0.56.1 (2026-07-27) | **Deprecation notice shown for `.conf` configs at startup.** |
| 0.55 → ~0.57 | **hyprlang will be dropped.** "The old hyprlang syntax will continue to be supported for 1–2 releases starting from 0.55. After that, hyprlang will be dropped. New config features will also not be added to hyprlang anymore." |
| after drop | `.conf` files will no longer load. New Lua-only features (events, timers, live gestures, dynamic rules, layouts) are not backported. |

You are on **Hyprland 0.56.2** — the deprecation notice is already active. Every day a `.conf`
config remains is a day it grows more stale relative to the Lua API.

---

## Document index (read in this order)

| # | Document | Purpose |
|---|---|---|
| **00** | `00-README.md` | You are here. |
| **01** | `01-background-and-timeline.md` | Why Lua, official timeline, what changed and what did NOT change. |
| **02** | `02-lua-syntax-crash-course.md` | The ~20 minutes of Lua you need to write Hyprland configs. |
| **03** | `03-config-loading-and-file-structure.md` | `hyprland.lua` bootstrap, `require()`, error handling, reload, REPL. |
| **04** | `04-migration-strategy.md` | The 7-phase migration plan with checklists, risk matrix and timeline. |
| **05** | `05-hyprlang-to-lua-mapping.md` | **Master cheat sheet**: every hyprlang statement → Lua equivalent. |
| **06** | `06-migrating-settings-and-variables.md` | `hl.config()`, categories, colors, runtime toggles. |
| **07** | `07-migrating-keybinds.md` | `hl.bind()`, dispatchers, flags, submaps, loops (152 binds → ~60 lines). |
| **08** | `08-migrating-monitors-and-workspaces.md` | `hl.monitor()`, nwg-displays, workspace rules, smart gaps. |
| **09** | `09-migrating-window-rules.md` | `hl.window_rule()`, `match`, effects, layer rules, handles. |
| **10** | `10-migrating-autostart-and-environment.md` | `hl.on("hyprland.start")`, `hl.env()`, exec patterns. |
| **11** | `11-migrating-animations-and-devices.md` | `hl.curve()`, `hl.animation()`, `hl.device()`, gestures. |
| **12** | `12-automated-tools-and-lsp.md` | Converters, `--verify-config`, LSP stubs, validation gates. |
| **13** | `13-testing-validation-rollback.md` | Per-module testing, A/B switching, rollback, git workflow. |
| **14** | `14-advanced-lua-patterns.md` | Events, timers, handles, dynamic config, gamemode, perf rules. |
| **15** | `15-hyprflux-specific-plan.md` | **The concrete HyprFlux file-by-file migration plan.** |
| **16** | `16-troubleshooting-and-gotchas.md` | Every reported pitfall with fixes. |
| **99** | `99-appendix-api-reference.md` | Full API reference extracted from the official wiki (fetched 2026-08-10). |

---

## Quick decision guide

- **Is my Hyprland ≥ 0.55?** → `hyprctl version` (this repo targets 0.56.2). If yes, migrate now.
- **Do I use plugins that ship `.conf` sections?** → their config sections are Lua-only now
  (`hl.plugin.<name>`); check for updates before converting those.
- **Does my config use `workspace_swipe` / `workspace_swipe_fingers`?** → removed; use `hl.gesture()`.
- **Do I use `hyprctl dispatch ...` in scripts?** → keep working (legacy), but plan to move to
  `hyprctl eval '...'` / direct dispatchers.
- **Hyprlock / Hypridle / Hyprpaper configs?** → **do not convert**, they are still hyprlang by design.

## Key facts to remember during migration

1. **`$VAR` is NOT expanded in Lua.** `"$HOME/..."` creates a literal `$HOME` folder. Use
   `os.getenv("HOME") .. "/..."`.
2. **Hyphenated keys become underscores.** `tap-to-click` → `tap_to_click`, `input-capture` → `input_capture`.
3. **Colors**: `"#rrggbbaa"`, `"rgb(...)"`, `"rgba(...)"`, or legacy `0xAARRGGBB`.
4. **Keybind handlers must not block.** No `io.popen`, `wl-paste`, sleeps, network I/O in bind
   lambdas — use `hl.dsp.exec_cmd()` (spawns async) instead.
5. **`source =` becomes `require("...")`** (paths relative to `hyprland.lua`, `/` or `.` separators,
   wildcards allowed, errors isolated per file).
6. **`exec-once` becomes `hl.on("hyprland.start", function() hl.exec_cmd(...) end)`.**
7. **Validation gate:** `Hyprland --verify-config` + `luac -p` + the LSP stubs
   (`/usr/share/hypr/stubs/`) before every boot test.
8. **nwg-displays already writes Lua** (`monitors.lua` — your live config already has one).

---

*Generated for HyprFlux (github.com/ahmad9059/HyprFlux). Sources: wiki.hypr.land (0.56.2 era),
github.com/hyprwm/Hyprland releases & PRs, community reports. Last updated: 2026-08-10.*
