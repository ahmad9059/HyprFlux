# Desktop script workflow fixes

Date: 2026-11-08. Follow-up to the Hyprland audit and desktop helper review.
Scope: reported script/workflow defects, both repository config trees, and
selective deployment to the maintainer's live Hyprland config. No unrelated
application settings, package upgrades or personal data migrations.

## Removed features

Removed `SyncBlog.sh`, `ObsidianGenerate.sh` and `notes-ai`, including their
`SUPER+SHIFT+B/N` shortcuts, cheat-sheet entries and current architecture
inventory. Historical audit/work-log entries are retained as history. Existing
notes, blog repositories, AI tools and their credentials are not deleted.

## Implemented repairs

| Workflow | Repair |
|---|---|
| HyprFlux updates | Read-only, timeout-bounded GitHub API version check. Never automatically stashes, clones, pulls, invokes `dotsSetup.sh`, or replaces live configs. An available update requires a separately reviewed deployment. |
| Dropdown terminal | Unique per-session app-id; only that client can be moved. Private runtime lock serializes requests; startup waits up to 8 seconds, never falls back to an unrelated window. Argument/Lua serialization handles quotes and spaces. Focused-monitor geometry accounts for scale and rotation. Existing windows are rediscovered by identity after helper restarts. |
| Game mode | Typed JSON snapshot preserves four-sided CSS gaps, booleans and numbers. No sourced shell state and no wallpaper-daemon kills. Failed enable removes staged state; failed restoration retains it. Changed/reloaded settings invalidate old state rather than being overwritten. |
| Audio | Fixed nonexistent mic-decrease function and stray `u` argument. Commands check failures before notifying. Icons query actual mute state; numeric notification hints contain only numbers. |
| Sounds | Valid `paplay` fallback, quoted paths, checked theme lookup and inherited-theme search. Missing sound files return failure without executing an empty path. |
| Wallpaper preview | Uses public `awww query` output, not undocumented version-specific cache paths. Atomic preview symlink and effects-cache updates. |
| Wallpaper selection | Index-based menu retains exact file identity for duplicate basenames and spaces. Case-insensitive extensions, explicit empty-directory errors and normal cancellation. File collections exclude directories/non-images. |
| Wallpaper startup | One startup owner, bounded image-daemon readiness and argv-based video launch. Selection persists per output in `~/.local/state/hyprflux/wallpapers.json`; no sed rewriting of Lua, literal `$HOME`, broken concatenation or missing quoting. Existing image selections can still restore from awww's own cache. |
| Wallpaper effects | Fixed argv-based ImageMagick operations replace shell `eval`. Effects target the focused display; no process-wide kills or UI restarts. Original selected source remains available for “No Effects.” |
| Auto wallpaper | Single runtime lock, filtered image collection, refreshed focus each iteration and no 30-minute sleep after a failure. `HYPRFLUX_WALLPAPER_INTERVAL` configures successful-change intervals. |
| Music | Tracks only its own detached mpv process group, including `/proc` start time to guard against PID reuse. Uses SIGTERM, never `kill -9` on every mpv process. Local selection uses indices to disambiguate filenames. |
| Quick Settings | Every visible choice has a handler. Correctly reads the terminal before quoted comments; editor arguments are argv, not interpolated shell. Kitty themes work when Kitty/kitten are available; Rofi theme browser appears only when installed. Light/dark action explicitly changes application preference, not the GTK theme. |
| Animation/monitor presets | Lua files only; validate syntax before replacement. Atomic writes, checked reload/config errors and rollback on failure. Cancellation does nothing; obsolete `.conf` profiles are not advertised as applied. |
| Screenshots | Cancellation before capture creates no file. Captures use private temporary files and atomic final saves. Validate active-window geometry, sanitize filename components, copy only valid saved images, clean failures and propagate nonzero status. Clipboard failure preserves the saved image and reports failure. |
| Idle daemon | Startup and toggle use the installed user service rather than mixing raw launches with systemd. Status remains valid Waybar JSON; legacy standalone processes can be paused without creating another owner. |
| Refresh | Reloads running Waybar/SwayNC without kill/restart races. Does not kill Rofi, unrelated wallpapers or launch an absent RainbowBorders helper. |
| Portals | Explicit `--restart` recovery uses user services; no backend-wide killall or blind `/usr/lib` + `/usr/libexec` launches. Running this recovery will interrupt active sharing and is not performed automatically. |
| Distro updates | Entire transaction runs inside one terminal, including both apt steps. Success/failure reflects the actual command exit status; Arch has a pacman fallback. No package transaction is run during validation. |
| Touchpad | Runtime device discovery with optional exact-name `HYPRFLUX_TOUCHPAD` override. No hard-coded ASUS device. Lua toggle state follows configuration lifetime rather than a stale on-disk flag; missing hardware fails clearly. |
| Tuned profiles | Check optional tuned/polkit dependencies before acting; use a graphical authorization request instead of terminal-only sudo. A missing package is reported, not silently installed. |
| First boot | No longer overwrites installer-selected GTK/Kvantum/cursor defaults or competes to start a wallpaper daemon. Existing startup marker is preserved. |

## Implementation and storage

Shell entrypoints and existing keybindings remain stable. Stateful actions use
standard-library Python modules under `.config/hypr/scripts/hyprflux/`, with
`DesktopActions.py` as the dispatcher. No new Python packages are required.
Runtime logs/locks/PID records live in a private, per-Hyprland-instance directory
under `$XDG_RUNTIME_DIR`. Persistent wallpaper selections live under
`$XDG_STATE_HOME/hyprflux`, and generated effects under `$XDG_CACHE_HOME/hyprflux`.
Python bytecode is not written into the config tree.

Supported dropdown terminals: Kitty, Foot, Ghostty and Alacritty. Unknown
terminals fail instead of guessing a client. The dropdown is not pinned across
workspaces; it appears on the currently active workspace and hides in its own
special workspace. This avoids state-dependent pin toggles.

## Validation

- Added isolated workflow tests in `tests/test_workflows.py`: typed state,
  stale-state protection, failure/cancellation cleanup, exact file selection,
  safe serialization, PID reuse, preset rollback, service ownership and removals.
- Local suite: **63 tests**, **60 passed / 3 skipped** for the private-source
  parser permission guard. Latest-stable Arch container: **all 63 passed** on
  Hyprland **0.57.1**, including all 18 animation/monitor presets.
- **150 shell files** passed syntax checks (known self-extracting emoji scripts
  excluded). Python AST checks passed. Config-mirror parity passed.
- External commands are mocked for destructive/UI-sensitive paths. No package
  upgrade, external Git write/push, portal recovery, suspend, microphone change,
  or screen capture is needed to run these regression tests.

Hardware-specific playback, physical keys, display hotplug and
suspend/resume still require interactive testing; unit tests are not evidence
that every media URL or hardware driver is working.

## Live deployment and smoke checks

Verified, symlink-preserving backup before deployment:

`/home/ahmad/dotfiles_backup/hypr-before-script-fixes-20261108-025932-858761`

Backup permissions are `0700`. Its `.deployment-metadata/rofi-current-wallpaper`
also preserves the pre-refresh Rofi wallpaper link. Selectively deployed **37
files** and removed the **three requested scripts**. The startup Lua changes
were merged, not copied wholesale, preserving the live cursor customization.
Monitor placement, GPU configuration, keyboard mappings, shader and lock-screen
language were untouched. Existing notes, caches unrelated to these workflows,
repositories and credentials were not deleted.

Checks on the actual running **Hyprland 0.56.2**:

- Staged and deployed configs returned `config ok`; `reload config-only`
  succeeded and the final `configerrors` response is empty.
- Removed script files and `Sync blog` / `Obsidian generator` bindings are absent.
- Real game-mode enable/disable restored **every tracked option exactly**.
  The first smoke check exposed JSON-vs-Lua CSS-gap types; these now serialize
  as `{top, right, bottom, left}` tables. A real-parser regression test verifies
  both activation and asymmetric restoration on latest stable as well.
- A new, uniquely identified test dropdown was spawned, shown, hidden and shown
  again. Only that window was manipulated; it was closed afterward and the
  original focused window restored. No test dropdown remains.
- The fixed preview-sync script refreshed Rofi/cache from the actual focused
  output's wallpaper without changing the displayed wallpaper. The read-only
  update checker completed successfully (exit 0).
- Hypridle remains active as exactly one systemd-owned process; the status
  script returns valid Waybar JSON. Idle/suspend policy was not exercised by
  locking or suspending the machine.
- Deployed helper bytes match the repository (apart from the intentionally
  merged personal startup module). Full repository config-mirror parity passed.

The isolated 0.57.1 verifier still emits its previously observed Socket2 binding
diagnostic while returning `config ok`; no GPU/interactive-container session
is claimed. Live checks are separate from that parser-only evidence.
