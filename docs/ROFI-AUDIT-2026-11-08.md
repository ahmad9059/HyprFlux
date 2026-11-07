# Rofi safety and workflow fixes

## Scope

Keep the existing themes, shortcuts, personal DPI, and large wallpaper previews.
Consolidate script-backed menus in `hyprflux/rofi.py`; retain shell entrypoints
for existing bindings. Mirror configuration changes into `base-dots/config/`.

## Fixes

- Use index selection for discrete menus. Names stay data, not shell source.
- Launch Tmuxifier directly with project values in the environment.
- Preserve the current clipboard on cancellation, invalid selection, failed
  history decoding, and calculation errors. Keep binary clipboard entries intact.
- Require confirmation before clearing clipboard history.
- Stop on Rofi errors instead of reopening a failed menu.
- Use a nonblocking session lock for managed Rofi dialogs. Do not kill unrelated
  Rofi or YAD processes. Repeated launcher shortcuts leave the current menu open;
  use Escape to close it.
- Keep free-text input in the calculator and normal application launcher.
- Use dedicated animation and monitor themes, correct ignored theme properties,
  and add workspace descriptions. Label missing IPC keycodes instead of guessing.
- Store the unchanged 1,849 emoji rows and 22 radio stations under `scripts/data/`.

## Configuration

Optional environment overrides: `HYPRFLUX_PROJECTS_DIR`,
`HYPRFLUX_TMUXIFIER_BIN`, `HYPRFLUX_GITHUB_USER`, and `HYPRFLUX_MUSIC_DIR`.
Edit station URLs in `hypr/scripts/data/radio-stations.json`.

## Validation

Run `python -m unittest discover -s tests -v`. The Rofi tests cover cancellation,
errors, selection bounds, locking, clipboard safety, project-name injection,
repository path validation, resource migration, and all 15 real theme parses.
CI installs Rofi. Theme checks use `-dump-theme` with an isolated home and no
display; the installed development build crashes with `-rasi-validate`.

Live deployment is selective: back up Hyprland and Rofi, verify destination files
still match the backup, validate a staged copy, then replace only changed files.
Do not overwrite the personal master theme, wallpaper link, or unrelated settings.
Tests and smoke checks must not change the real clipboard, clone repositories,
or start music. Automated checks do not replace a visual desktop check.

### Verified results

- All 98 tests passed in the isolated image with real Rofi, Hyprland, GTK, and
  schema dependencies; no tests skipped.
- All repository shell scripts passed `bash -n`; staged live Lua and all 15
  themes passed parser checks. Configuration mirrors match.
- Selectively deployed 20 files after backup; Hyprland reloaded without errors.
- Eight deployed entrypoints passed cancellation smoke tests with mocked external
  commands. No real clipboard writes, cloning, or music playback occurred.
- Unrelated live files, the 144 DPI setting, and wallpaper links stayed unchanged.
- Hyprland IPC confirms SUPER+D and 30 workspace descriptions. Lua dispatchers
  expose callback IDs, not command text; verify their command via the Lua config.
