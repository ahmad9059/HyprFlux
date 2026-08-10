# 16 — Troubleshooting and Gotchas

Every reported pitfall from the community + official tracker, with fixes. Check this table
first when something behaves oddly after conversion.

## 16.1 The big four

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 1 | Literal `$HOME`/`$XDG_*` directories created | **`$VAR` is NOT expanded in Lua strings** | `os.getenv("HOME") .. "/..."`. Grep every string with `$` before booting. |
| 2 | "unknown config key" for `tap-to-click`, `input-capture` | hyprlang dashed keys rejected; registry maps `-` → `_` | use `tap_to_click`, `input_capture`, `drag_threshold`… |
| 3 | Desktop freezes on a keybind | blocking code in bind callback (`io.popen`, `wl-paste`, `sleep`, network) | `hl.dsp.exec_cmd(...)` or `hl.timer`; never block |
| 4 | Config won't reload / error popup after save | syntax error (kills reload) or runtime error (kills that file) | `luac -p`; check error popup; use emergency binds SUPER+Q/R/M |

## 16.2 Removed options checklist (grep your old configs)

```
gestures.workspace_swipe|workspace_swipe_fingers|workspace_swipe_min_fingers   → hl.gesture()
dwindle.pseudotile            (removed, did nothing)
decoration.shadow.ignore_window  (removed, default-on)
render.cm_fs_passthrough      (removed)
misc.vfr                      → debug.vfr
```

## 16.3 Common conversion errors

| Symptom | Cause | Fix |
|---|---|---|
| Rule silently not applied | named rules evaluated before anonymous; last-match-wins; both props must match (AND) | re-check order + props |
| Opacity too dark | rules **multiply** | add ` override` suffix for absolutes |
| `hl.unbind("SUPER + TAB")` no effect | case-sensitive exact match | `"SUPER + Tab"` |
| Workspace swipe does nothing | old gesture options removed | `hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })` |
| `require("foo")` fails intermittently | `package.path` was nuked on reload (≤0.56.0) | upgrade to ≥0.56.1; use relative paths |
| `require("nonexistent")` kills config | missing module throws in caller | `pcall(require, ...)` |
| Colors look wrong (inverted channels) | legacy `0xAARRGGBB` vs `"#rrggbbaa"` | pick one form; `rgba()` is unambiguous |
| `hyprctl dispatch setprop ...` errors | packed-param dispatchers moved to typed tables | `hl.dsp.window.set_prop({ prop, value, window })` |
| Bind triggers on wrong layout | binds resolve to first layout's keysym | `resolve_binds_by_sym = 1` or `code:` binds |
| `style = "loop"` kills battery | `*angle` loop forces constant rendering | remove loop / disable animation |
| Workspace rules match nothing | selectors only match **existing** workspaces | use ID/`name:` for rules, selectors for events |
| `--verify-config` segfault (0.55.0 only) | upstream bug | upgrade ≥0.55.1 (you're on 0.56.2) |
| `dwindle { }`/`master { }` block errors "unknown config key 'layout.dwindle.*'" | layout options are **flat keys** (`dwindle.*`, `master.*`), NOT nested under `layout` | `hl.config({ dwindle = { preserve_split = true }, master = { mfact = 0.5 } })` |
| `hl.animation` errors "speed 180 is more than the maximum of 100" | Lua API caps animation speed at 100 ds | clamp to ≤100 (borderangle 180 → 100) |
| `hl.bind: Unknown keysym "XF86AudioPlayPause"` | `XF86AudioPlayPause` is not a valid xkbcommon keysym (hyprlang accepted it) | bind `code:164` (KEY_PLAYPAUSE) with a comment |
| `hl.animation("borderangle"): unknown style` | a style string with a **trailing space** (`"loop "` vs `"loop"`) — e.g. produced by converters that swallow the space before a `#comment` | `style.strip()` in generators; grep `style = "[a-z]* "` |
| `hl.curve("nice"): point value 6.90 is more than the maximum of 2.00` | bezier control points are clamped to `[-2, 2]` in the Lua API (hyprlang accepted out-of-range) | clamp or drop the curve (check if it's used first) |
| `hyprctl config full-reload` → `unknown request` | the subcommand doesn't exist on 0.56.2 (added in a later release) | use `hyprctl reload` (verified working on 0.56.2) |
| Startup log still says "hyprland.conf" | cosmetic (hyprwm/Hyprland#15407) | ignore |
| `hyprctl binds` JSON empty/invalid | fixed in 0.56.1 | upgrade; use `hyprctl eval` |

## 16.4 Ecosystem fallout you may hit

- **Waybar workspace switching broke on 0.55** — fixed upstream (PR #5013); keep Waybar updated.
- **hyprpm plugins**: C++ ABI unaffected, but their config sections are Lua-only
  (`hl.plugin.<name>`), and plugin dispatchers were not discoverable via `hyprctl dispatch`
  on `.lua` configs in 0.55 (issues #14449/#14450). Test any plugin before relying on it.
- **nwg-displays** warning: don't set `misc.disable_autoreload = true`.
- **HyprSettings** GUI editor is `.conf`-era; don't use it on the Lua tree.
- **LLM-generated Lua** (Claude/Copilot one-shots): "works mostly but hallucinates windowrule
  options, key codes and colors" — always `--verify-config` + stub-file check.

## 16.5 API stability

The `hl.*` surface moves between patch releases. Things added after 0.55:
`hyprctl repl`, `hyprctl config full-reload`, `hl.dsp.release_input_capture`, typed stubs,
`package.path` fix. Pin the stub file to the installed Hyprland version; re-verify after
`pacman -Syu`.

## 16.6 Session-level failure recovery

1. Emergency binds (SUPER+Q/R/M) if binds failed to load.
2. From TTY: `loginctl terminate-session` — Hyprland restarts with the on-disk config.
3. Rollback: checkout pre-flip git tag / restore `~/.config/hypr.bak-hyprlang` (doc 13 §13.6).
4. If a config is broken *at startup* (syntax error), Hyprland refuses to reload — but will it
   boot with a broken file? It boots with the error popup and emergency binds; fix the file and
   `hyprctl reload`.

## 16.7 Final greps before shipping

```bash
grep -rn '\$' hyprland.lua UserConfigs/*.lua configs/*.lua        # stray $VAR
grep -rn 'hyprctl keyword' scripts/ UserScripts/                  # old config writes
grep -rn 'source *=' .config/hypr                                 # legacy includes left
find .config/hypr -name '*.conf' | grep -v hyprlock | grep -v hypridle | grep -v application-style
```

Next: [99-appendix-api-reference.md](99-appendix-api-reference.md) (full API reference)
