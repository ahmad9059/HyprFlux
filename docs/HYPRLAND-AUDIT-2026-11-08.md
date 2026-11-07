# Hyprland configuration audit

Date: 2026-11-08. Scope: `.config/hypr/`, its `base-dots/config/hypr/`
mirror, launch/refresh helpers, installer interactions, CI, and differences in
`/home/ahmad/.config/hypr/`. This is a source and isolated-parser audit, not a
claim that every application or hardware path was exercised interactively.

**Follow-up:** the game-mode, dropdown, wallpaper/first-boot and touchpad helper
findings were subsequently repaired and selectively deployed. See
[Script workflow fixes](SCRIPT-WORKFLOW-FIXES-2026-11-08.md) for the current
implementation, requested feature removals, 63-test results and live smoke
checks. The batch-1 status table below records the historical first pass.

## Version baseline and method

- Installed **and running**: Hyprland **0.56.2**, commit
  `efb50993780079460b0cbed1363e2166a2de1d9f`.
- Latest stable reported by upstream's releases API: **0.57.1**, published
  2026-11-03. Current wiki content can describe newer main-branch behavior;
  release-tagged source takes precedence when checking 0.57.1 semantics.
- Initial live `hyprctl configerrors`: empty. Initial repository verification
  with installed 0.56.2: `config ok`. These do not prove callback correctness.
- Initial tests: 9 tests, 8 passed, 1 skipped because the source directory is
  private. The existing isolated verifier must not expose the user's home.
- Checked API documentation through Context7 and read upstream 0.57.1 release
  source. Compared live overrides without copying credentials or unrelated
  application data. No package upgrade, desktop reload, suspend, or interactive
  dispatcher was performed on the host.
- Validation results and implementation status are recorded at the end.

## Executive summary

The Lua entrypoint and environment-before-settings load order are sound. The
repository already removed `dwindle.special_scale_factor`, uses current window
rule tables, and has an isolated verification script and mirror-parity CI.
The largest remaining risks are **runtime behavior**, not basic Lua syntax:
conflicting shortcuts, a shell-invalid resume command, legacy dispatcher
arguments, inaccurate state restoration, and hardware-specific assumptions.

Do not reinstall the dotfiles to deploy audit fixes: `modules/02-dotfiles.sh`
deletes matching live config folders. That would remove personal overrides.

## Findings

Severity: High = broken core behavior or security/reliability concern;
Medium = reproducible feature failure; Low = maintenance or optional policy.
Locations below describe the pre-fix state; use symbols rather than line
numbers because fixes move lines.

### H01 — Multiple actions share the same shortcut (High)

- Evidence: `configs/keybinds.lua` assigns `SUPER+K` to master `cycleprev`
  and `SUPER+O` to dwindle `togglesplit`. `UserConfigs/user-keybinds.lua`
  assigns those combinations to Kdenlive and Obsidian. The same user module
  registers `SUPER+SHIFT+W` twice for independent Rofi wallpaper menus.
- Impact: both actions can run, unexpectedly launching apps or competing menus.
- Fix: preserve layout shortcuts; move apps to `SUPER+ALT+K/O`, and wallpaper
  effects to `SUPER+CTRL+W`. Update hints and add duplicate-binding tests.

### H02 — Silent window moves use the wrong API (High)

- Evidence: numeric/bracket binds pass `workspace = "1 silent"` or equivalent
  to `hl.dsp.window.move`. `scripts/Dropterminal.sh` repeats this pattern.
- Upstream `LuaBindingsDispatchers.cpp` reads a workspace selector and a
  separate `follow` boolean; `follow = false` selects a silent move.
- Impact: a workspace selector may fail or resolve incorrectly at invocation.
- Fix the dispatchers to use `follow = false`. **Do not** remove `silent` from
  window-rule or `hl.exec_cmd` rule strings: those use a different grammar.

### H03 — Resume command is invalid shell syntax (High)

- Evidence: `hypridle.conf` embeds `hl.dsp.dpms({ ... })` unquoted in commands.
  The shell interprets `(` before `hyprctl` can receive the expression.
- Impact: displays may not be explicitly re-enabled after resume. Commented
  screen-off examples would also fail if enabled.
- Fix: single-quote the entire Lua dispatcher expression. Explicitly select
  `inhibit_sleep = 3` to wait for the session-lock notification on suspend.
  Existing default auto-detection may already choose this mode; omission is
  not evidence that the current host sleeps unlocked. Test suspend manually.

### H04 — Telegram shortcut starts a pipeline, not a fallback (Medium)

- Evidence: the command is `(64gram-desktop|telegram-desktop)`.
- Impact: shell launches both sides of a pipe, not the first installed app.
- Fix: select using `command -v`; only launch one installed client.

### H05 — Color picker arguments are malformed (Medium)

- Evidence: `hyprpicker -a / –autocopy` contains an accidental `/` argument
  and a Unicode en dash. `-a` already requests clipboard copying.
- Fix: use `hyprpicker -a` and assert the exact command in tests.

### H06 — Play/pause uses a Linux input code as an XKB code (Medium)

- Evidence: `code:164` is documented as `KEY_PLAYPAUSE`. Local XKB evdev
  keycodes map `I164` to `KEY_BOOKMARKS` and `I172` to `KEY_PLAYPAUSE=164`.
  Hyprland code binds use XKB codes, as the number-row bindings also show.
- Fix: remove the incorrect code bind; retain `XF86AudioPlay` and
  `XF86AudioPause` keysym bindings. Avoid adding code:172 on top of the same
  Play keysym, which could execute play/pause twice.

### H07 — Layout controls are inconsistent across workspaces (Medium)

- Evidence: `ChangeLayout.sh` reads/writes global `general.layout`, rather
  than the active workspace's `tiled_layout`. Layout-specific workspace rules
  can prevent the visible layout from changing. `SHIFT+I` dispatches dwindle
  `rotatesplit` without the guard used by other layout messages. Existing
  guards ignore an open special workspace and assume a workspace exists.
- Fix: cycle the active special/normal workspace using `hl.workspace_rule`;
  guard layout-only callbacks and handle an absent workspace.

### H08 — Game mode does not restore its advertised state (High)

- Evidence: `GameMode.sh` parses `hyprctl getoption` display text with awk,
  serializes only one edge of CSS gaps, and sources the resulting state as
  shell code. Bool text can become `1/0` in Lua config instead of booleans.
  It writes the marker before confirming successful application.
- Impact: restore can fail or lose asymmetric gaps; state can become stale
  after config reload. No untrusted-user exploit was demonstrated.
- Recommendation: use typed JSON or in-process Lua state, preserve all four
  gap values, commit state only after success, and test repeated toggles and
  reloads. Avoid broad daemon restarts as a side effect of visual toggles.

### H09 — Dropdown terminal can select the wrong window (High)

- Evidence: `Dropterminal.sh` stores an address in shared
  `/tmp/dropdown_terminal_addr`, interpolates an unescaped terminal command
  into Lua, waits just 100 ms, and falls back to an arbitrary client from
  `focusHistoryID`. It uses monitor `[0]` physical pixels, ignoring focus,
  scale and rotation. Several errors are discarded.
- Impact: slow startup or another concurrently opened window can cause an
  unrelated application to be pinned, moved, or hidden. Multi-monitor sizing
  is wrong on mixed-DPI setups. Single quotes in a command break Lua syntax.
- Recommendation: redesign around a unique terminal app-id/title, a private
  session runtime directory and lock, bounded identity-based polling, Lua-safe
  serialization, and focused-monitor logical geometry. H02 is independently
  fixable, but does not resolve this broader finding.

### H10 — Refresh helper calls a nonexistent wallpaper script (Medium)

- Evidence: `RefreshNoWaybar.sh` executes `WallpaperSwww.sh`; the maintained
  script is `WallpaperAwww.sh`.
- Impact: animation/profile refresh paths emit a missing-command error and
  fail to refresh the wallpaper integration.
- Fix: use the maintained script and quote its path.

### H11 — First boot overrides installer theme choices (Medium)

- Evidence: `initial-boot.sh` applies `Material-DeepOcean-BL`, `Moga-Cursor`,
  and `catppuccin-mocha-blue`, while setup modules use `HyprFlux-Compact`,
  `Future-black Cursors`, and the installed theme configuration. Its
  `awww query || awww-daemon && ...` can wait forever on a foreground daemon.
  The startup module also starts `awww-daemon`, so first boot has two owners.
- Recommendation: make installer state authoritative; first boot should only
  initialize unset state, serialize initialization, and wait with a deadline
  for a single wallpaper service. Do not remove the live startup marker.

### H12 — Touchpad toggle is tied to one ASUS device (Medium)

- Evidence: `laptops.lua` and `TouchPad.sh` hard-code
  `asue1209:00-04f3:319f-touchpad`. The script's first invocation always enables
  it; a file, not actual device state, decides future operations.
- Impact: shortcut is ineffective on other laptops and can disagree with a
  compositor reload. Tool-availability guards are appropriate for ASUS apps,
  but a missing binary does not mean the key itself can never fire.
- Recommendation: discover touchpads using supported device data, permit an
  explicit override, query state and handle missing devices. `hl.get_devices`
  is new in 0.57: do not introduce it without a version/capability policy.

### H13 — Toolkit environment exports conflict or force old workarounds (Low)

- Evidence: `env-variables.lua` exports `QT_QPA_PLATFORMTHEME` twice; the
  second (`qt6ct`) replaces `qt5ct`, rather than selecting by Qt version.
  Scale variables force global values; Code/Obsidian shortcuts force X11.
- Recommendation: use a supported Qt5/Qt6 selection mechanism and explicitly
  choose native Wayland versus per-app XWayland overrides. Test both toolkits,
  IME, fractional scaling and screen sharing before changing defaults. These
  are compatibility policy decisions, not proven failures on this host.

### H14 — Workspace documentation contradicts actual load order (Low)

- Evidence: `UserConfigs/workspace-rules.lua` says it is not sourced and must
  be enabled manually; the entrypoint already requires it. It loads before
  generated `workspaces.lua`, which can override user rules for the same key.
- Fix misleading comments. Decide/document which file owns monitor placement
  before changing load order: the live file contains important monitor rules.

### H15 — Fullscreen apps inhibit all idle behavior (Low / policy)

- Evidence: `windowrule-60` applies `idle_inhibit = "fullscreen"` to every
  fullscreen window, not only video or games.
- Impact: any fullscreen client can indefinitely postpone the 10-minute idle
  lock. This is expected configured behavior, not a lock bypass once locked.
- Recommendation: retain only if intentional; otherwise use application-based
  rules or explicit user-controlled presentation mode. Do not silently change
  a user's power-management policy during compatibility fixes.

### H16 — Gesture tuning exists without a gesture binding (Low / optional)

- Evidence: `user-settings.lua` configures workspace-swipe parameters but only
  shows `hl.gesture` in a comment. No active gesture is registered elsewhere.
- Recommendation: either document swipes as opt-in or enable a documented
  gesture after checking application conflicts. Parameters alone do not bind
  a gesture. Not a parser error or a mandatory upgrade change.

### H17 — Verification misses runtime callbacks and standalone presets (Medium)

- Evidence: current tests chiefly cover desktop deployment; Lua syntax and
  the main config parser cannot exercise a key press, shell command parsing,
  silent workspace selection, duplicate shortcuts, or every unused preset.
  Shell CI's find roots omit the primary `.config/hypr` scripts. The full
  mirror check is useful but is not behavioral testing.
- Fix: add a side-effect-free Lua harness, typed dispatcher assertions,
  callback tests, idle-command shell checks, and primary-script shell CI.
  Keep both supported-version and latest-stable parser evidence explicit.

### H18 — Live settings have upgrade risks not present in distro defaults (Medium)

- Live `user-settings.lua` still sets `dwindle.special_scale_factor = 1`,
  deprecated in 0.57.0; the repository already removed it. Do not reintroduce
  it when synchronizing. There is no need to restore a redundant value.
- Live OLED shader is absent from the repo. Retain the shader and its
  reference together; evaluate color-managed/HDR rendering visually on 0.57.
- Live monitor names, coordinates, GPU DRM paths, keyboard remaps, Urdu
  lock-screen formatting and tablet output are personal, not distro defects.
- Live Foot configs differ from the repository's already repaired configs.
  This is adjacent to Hyprland; do not overwrite them as part of this audit.
- Recommendation: perform a selective deployment and inspect the actual live
  files again before applying fixes. Never mirror entire directories blindly.

## Sources

1. [Latest release API](https://api.github.com/repos/hyprwm/Hyprland/releases/latest)
2. [0.57.1 release](https://github.com/hyprwm/Hyprland/releases/tag/v0.57.1)
3. [0.57.0 release / migration changes](https://github.com/hyprwm/Hyprland/releases/tag/v0.57.0)
4. [Tagged dispatcher implementation](https://github.com/hyprwm/Hyprland/blob/v0.57.1/src/config/lua/bindings/LuaBindingsDispatchers.cpp)
5. [Tagged option definitions](https://github.com/hyprwm/Hyprland/blob/v0.57.1/src/config/values/ConfigValues.cpp)
6. [Dispatchers](https://github.com/hyprwm/hyprland-wiki/blob/main/content/configuring/core/dispatchers.md)
7. [Binds](https://github.com/hyprwm/hyprland-wiki/blob/main/content/configuring/core/binds/binds.md)
8. [Window rules / dynamic tag semantics](https://github.com/hyprwm/hyprland-wiki/blob/main/content/configuring/core/rules/window-rules.md)
9. [Hypridle / sleep inhibition](https://github.com/hyprwm/hyprland-wiki/blob/main/content/hypr-ecosystem/user/hypridle.md)
10. [Using hyprctl](https://github.com/hyprwm/hyprland-wiki/blob/main/content/configuring/core/advanced-configuration/using-hyprctl.md)
11. Local `/usr/share/X11/xkb/keycodes/evdev`, entries I164 and I172.

## Remediation and validation log

Audit written before implementation. First batch targets confirmed shortcut,
dispatcher, idle-shell and refresh bugs, plus regression coverage. Complex
stateful helper redesigns and policy choices remain separately tracked rather
than being labeled fixed by a partial change. Live deployment is not automatic.

### Batch 1 — implemented in both repository config trees

| Finding | Status | Implementation / remaining verification |
|---|---|---|
| H01 | Fixed | Unique app/wallpaper shortcuts; hints and architecture table updated. |
| H02 | Fixed | Number/bracket and dropdown dispatchers use `follow = false`; rule-string grammar retained. H09 remains open. |
| H03 | Fixed in source | All five DPMS command examples quoted; explicit sleep inhibition. Physical suspend/resume remains untested. |
| H04 | Fixed | Telegram checks availability and launches just one client. |
| H05 | Fixed | Picker uses only `-a`. |
| H06 | Fixed | Removed wrong raw media code; retained Play/Pause keysyms. |
| H07 | Fixed in source | Workspace-local cycle, special-workspace priority, nil guards, guarded rotatesplit. Interactive layout checks remain. |
| H08 | Open — next high-priority batch | Game-mode typed state and exact restoration need redesign and failure-path tests. |
| H09 | Open — next high-priority batch | Only silent-dispatch syntax repaired; identity, runtime storage and geometry still require redesign. |
| H10 | Fixed | Refresh invokes the existing `WallpaperAwww.sh`. |
| H11 | Open | Consolidate first-boot theme/wallpaper ownership without resetting existing installations. |
| H12 | Open | Portable device discovery and actual-state toggle needed. |
| H13 | Open / compatibility policy | Test toolkit and per-app backends before changing exports. |
| H14 | Fixed documentation | Correctly describes actual loading and precedence; load order intentionally unchanged. |
| H15 | Decision required | Fullscreen idle-inhibition policy preserved. |
| H16 | Optional | Gestures remain opt-in. |
| H17 | Improved | Behavioral harness, shell-command checks, all preset verification, primary shell CI. Real hardware/UI tests still needed. |
| H18 | Open / live only | Personal settings were not overwritten; remove redundant deprecated scale selectively when deploying. |

Changed shortcuts:

- Kdenlive: `SUPER+ALT+K` (was `SUPER+K`, which remains master cycle-previous).
- Obsidian: `SUPER+ALT+O` (was `SUPER+O`, which remains dwindle toggle-split).
- Wallpaper effects: `SUPER+CTRL+W`; selection remains `SUPER+SHIFT+W`.
- Layout cycling now affects only the visible normal or special workspace,
  not the global default for every workspace.

### Verification results

- **Latest stable 0.57.1**, commit
  `acc1aa0bfd4bd575dcb0f76c35ccf12b660a1ab9`: all **17 unittest tests passed**
  in an isolated Arch container. This includes valid/invalid parser exit-code
  tests and all **17 animation presets + 1 monitor preset** with the real
  compositor verifier. Main config also returned `config ok` separately.
- The standalone latest verifier printed a Socket2 binding diagnostic in the
  isolated container, but returned success and `config ok`; it was not treated
  as evidence that an interactive Wayland/GPU session had been tested.
- **Installed 0.56.2**: main configuration returned `config ok`; local unittest
  run: **15 passed, 2 skipped** (private-source permission guard). Those two
  skipped parser tests passed in the isolated 0.57.1 container instead.
- **152 shell scripts** checked with `bash -n`: no failures. The known
  self-extracting `RofiEmoji.sh` files remain excluded, matching existing CI.
- Full `.config` / `base-dots/config` parity: passed, without dereferencing
  wallpaper symlinks. Lua syntax checks: passed. `git diff --check`: passed.
- Regression checks exercise duplicate registrations, typed silent moves,
  layout callback guards, special workspaces, missing workspaces, shell quoting,
  exact DPMS argument boundaries, Telegram client selection, picker arguments,
  media bindings, refresh-helper existence and mirror contents.
- No live configuration files were edited for this batch; no desktop reload,
  GPU/display operation, suspend, service restart or host package upgrade ran.
  Latest-version packages were installed only in a Docker validation image
  (`hyprflux-config-audit:2026-11-08`), not on the host. Tests used a copied
  repository snapshot with no host session sockets/devices or network access.

### Next batch and deployment order

1. Repair H08 state handling and test enable/disable/failure/reload sequences.
2. Redesign H09 around a uniquely identified terminal; test concurrent launches,
   launch timeouts, close/reopen, multi-monitor scale/rotation and stale state.
3. Address H11/H12 ownership and hardware portability, then decide H13/H15/H16.
4. Selectively apply reviewed changes to live files, preserving GPU settings,
   monitor placement, keyboard mappings, shader and lock-screen language.
5. Validate the resulting live source, then deliberately reload/restart the
   affected components. Test physical media keys, both layouts, special
   workspaces, monitor reconnect, idle lock and suspend/resume before release.

### Live deployment — 2026-11-08

Applied batch 1 at the user's request after creating and hash-verifying a
complete, symlink-preserving backup of `~/.config/hypr`:

`/home/ahmad/dotfiles_backup/hypr-before-audit-20261108-024413-708246`

The backup directory is private (`0700`). Eight audited files were copied
selectively; only the introductory comments were changed in live
`UserConfigs/workspace-rules.lua`, preserving both custom monitor-placement
loops. Manifest comparison confirmed exactly **nine intended files changed**,
with every other backed-up file, symlink and file permission preserved.
No installer or whole-directory mirror was run. H18's personal settings and
deprecated scale option remain untouched.

Live validation on **0.56.2**:

- Staged merged config and deployed config: real verifier returned `config ok`.
- `hyprctl reload config-only`: successful; `hyprctl configerrors`: empty.
- **143 live bindings** registered. App and wallpaper shortcuts match their
  new combinations; reported key combinations have no duplicates. This
  version's JSON omits identifying keycodes for 30 raw-code binds, so those
  were verified through the source callback harness, not inferred from JSON.
- Callback harness passed against the actual live modules. Running-compositor
  smoke checks accepted all 12 silent-move dispatcher factories and the
  special/normal workspace query API without moving any windows. Dispatcher
  objects in the real API are callable userdata, not plain Lua functions.
- Replaced the previously standalone idle process with the installed
  `hypridle.service` for this session, without enabling it for future logins.
  Exactly one daemon is running; its journal confirms waiting for the session
  lock before releasing sleep inhibition. No configuration parse errors.
- Executed the actual quoted `after_sleep_cmd`: returned `ok`. Both displays
  were already powered on and remained on.

No app was launched, window moved, layout cycled, display powered off, screen
locked, or system suspended for these checks. Physical-key and full
suspend/resume behavior still need an interactive test; H08/H09 and the other
open findings above are not resolved by deploying batch 1.
