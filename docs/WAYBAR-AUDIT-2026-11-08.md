# Waybar audit and improvements — 2026-11-08

## Outcome

**Design rollback requested by the user:** restored the previous module layout,
Cava/media placement, centered workspaces/clock/weather, original Nerd Font,
rounded sections, calendar colors and module colors. Removed the new compact
preset. The original design takes precedence over the audit's visual proposals.
Only undefined/no-op CSS animations remain removed; no new color scheme is used.

The design rollback was backed up under
`~/dotfiles_backup/waybar-before-design-rollback-20261108-133131` and deployed
on both monitors. The fresh restored bar log is
`/tmp/opencode/waybar-classic-live.log`. All 168 tests still succeed (four skips).

Retained the configuration/helper fixes, organized include structure, working
personal overrides, sensor detection, tests and installer preservation fixes.
The live machine's per-monitor workspace assignments remain unchanged.
The live bar was backed up before deployment and restarted without restarting
Hyprland, changing power policy, or triggering a system update.

Usage and file ownership are documented in
[the Waybar README](../.config/waybar/README.md).

## Findings and fixes

The table records the initial audit. Its alternate layout, native-MPRIS default,
opt-in-Cava default, compact preset and visual/state redesign were subsequently
withdrawn. The safe custom media helper and private per-bar Cava processes remain
active in the restored original layout.

| Finding | Change |
| --- | --- |
| Duplicated entrypoint/preset layout | `config` now selects one shared preset. Added an optional compact preset. |
| Personal overrides included last | `UserModules` is first, matching Waybar's first-defined-wins merge semantics. |
| Repeated spacer/launcher modules, missing default network controls | Removed fake spacers and duplicate terminal placement; added the connections drawer. |
| Malformed, unquoted workspace Lua commands and nonexistent `$WORKSPACE_ID` usage | Native clicks; quoted Lua for scroll-enabled variants. Checked installed Waybar for native Lua IPC translation. |
| Duplicate JSON keys, obsolete workspace sorting option, missing vertical logout module | Removed duplicate definitions, use `sort-by`, and reference an existing safe logout-menu module. |
| `actions` outside clock; audio sink filtering inside icon map | Moved settings into their owning module objects. Kept current `disk.paths` API; corrected an initial deprecated `path` edit after the live startup warning. |
| Unescaped player metadata spliced into JSON | Default native MPRIS, with serialized JSON for the retained legacy custom module. |
| No-player output and missing/stale keyboard cache | Native modules by default; compatibility helpers produce defined empty/current states. |
| Update checks ran twice, conflated errors/zero updates and used a shell-specific test | Single locked check, explicit exit-code handling, bounded timeout, shared cache, JSON states, current-user refresh signal. No package transaction during checks. |
| Shared Cava temp file and broad kill command broke multiple bars | Private configuration per instance, owned-child cleanup, 15 fps, opt-in rather than always running. Two-instance lifecycle regression test. |
| Fragile grep-based app launch and terminal flags | Shared argv-based launcher reads literal defaults and supports known terminal adapters. Missing tools fail without auto-installation. |
| Browser opened incomplete URL; launcher killed arbitrary Rofi dialogs | Valid browser target and existing managed launcher. |
| Optional quit/reboot modules executed immediately or used invalid syntax | Open the power menu instead; tooltips describe the action. |
| Sensor tied to mutable `hwmonN`; installer used fragile sed range replacement | Stable CPU device paths, structured JSON hardware setup by sensor name, both orientations updated. Personal overrides retain precedence. |
| Undefined CSS animations, hover padding jumps, no clear critical/error feedback | Consistent spacing, readable typography, fixed workspace hit areas, active/urgent/critical/muted/disconnected/update states, matching tooltips. |
| Weather parse errors, raw markup, severe weather classified as ordinary rain, assumed daytime | Error JSON, escaped markup, severe class, sunrise/sunset using location observation time, atomic hyprlock cache writes. |
| Legacy copy pipeline restored Waybar then overwrote it again | Removed Waybar from second copy phase; preserved personal overrides and relative preset/theme selections. |
| Legacy installer could recreate links to removed layouts/styles and delete presets | Removed obsolete symlink/cleanup logic and no-op clock JSON sed rewrites. |

## Live machine preservation

Backup: `~/dotfiles_backup/waybar-before-audit-20261108-131740`.

The old live workspace bank differed from the repository: external `DP-2` used
workspaces 1–5 and internal `eDP-1` used 6–10, with `all-outputs=false`. Those
settings were moved to the live `UserModules`; the shared repository does not
embed these output names. Other personal Hyprland configuration was not replaced.

Existing `.bak` files were left alone. The live log is
`/tmp/opencode/waybar-live.log`; its initial disk deprecation warning was corrected
before the final check. Ordinary tray registration messages are informational.

## Validation and boundaries

- Final local suite: **168 tests, successful, four skips** (three isolated-container
  Hyprland verifier tests and the unavailable SwayNC schema check). Includes
  **32 Waybar regressions**. Shell syntax, whitespace, and full deployment-mirror
  parity checks also passed.
- Configuration tests cover every module bank/preset, duplicate keys, includes,
  group references, shell action syntax, correct option placement and mirror parity.
- Actual GTK3 CSS parsing, plus stubbed update/media/tool-launch tests.
- Independent Cava child lifecycle, weather failure/escaping/day-night tests,
  and disposable-home installer preservation tests. No real upgrades or power
  transitions occur in the suite.
- Live startup/reload on both 2560×1440 outputs and a cropped bar visual check.
- The legacy `hyprctl dispatch workspace N` command was confirmed incompatible
  with this Lua configuration. The installed Waybar has native Lua translation;
  scroll commands use the working quoted Lua dispatcher form.

These checks are not a claim that every optional module, Bluetooth device,
terminal, player, DPI setting or future Waybar build has been hardware-tested.
Media correctly hides when no media player advertises itself. The restored
original layout is not automatically rearranged by monitor width.
Temperature defaults target common AMD/Intel hosts, with installer or
personal configuration needed for other sensors.

No suspend/hibernate policy was changed in this work. No ISO files were edited.
