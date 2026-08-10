# 12 — Automated Tools, Converters and LSP

Machine assistance is the difference between a 2-day and a 2-week migration. Community tooling
matured fast — use it, but always gate with `--verify-config`.

## 12.1 Converters

### hyprlang2lua (recommended) — Go CLI

- Repo: https://github.com/EIonTusk/hyprlang2lua — web converter: https://eiontusk.github.io/hyprlang2lua/
- AUR + Nix packages available.
- Converts the full bind family, submaps, nested sections, typed dispatchers.
- `--check` mode for CI (exit code 3 on mismatch), golden tests against real
  `Hyprland --verify-config`, tracks the 0.56.1 API surface.
- Per-file: `hyprlang2lua -i input.conf -o output.lua`

### hyprconf2lua — Python

- PyPI: https://pypi.org/project/hyprconf2lua/ — repo: https://github.com/Prateek-squadron/hyprconf2lua
- `pipx install hyprconf2lua`
- ~97% clean conversion, 0% false positives: everything it flags genuinely needs attention.
- `--dir` and `--in-place` options for converting whole directories of sourced files.

### What converters do NOT do

- Reorder/precedence analysis (rules order must stay)
- `$VAR` expansion → locals (they usually emit `local` defs — verify paths!)
- Script changes (your `scripts/*.sh` still call `hyprctl dispatch`)
- hyprlock/hypridle files (out of scope by design)
- Refactoring into loops (they emit 1:1 binds — refactor is doc 14)

**Workflow:** convert → review diff → `luac -p` → `Hyprland --verify-config` → fix flagged items
→ boot-test. Expect to hand-fix ~3–5% (typically colors, `$VAR` in strings, dispatchers with
packed params).

## 12.2 Validation gates (run at every phase boundary)

```bash
# 1. Lua syntax (pure)
luac -p hyprland.lua

# 2. Config semantic validation (headless, against real binary)
Hyprland --config ~/.config/hypr/hyprland.lua --verify-config
# or at runtime:
hyprctl verify-config

# 3. Live state diff (before/after migration)
hyprctl binds            # count + names
hyprctl getoption general:gaps_in
hyprctl monitors all
hyprctl clients          # window rules applied correctly
```

> `Hyprland --verify-config` is the community's de-facto acceptance test. It catches exactly the
> failure class `luac -p` cannot: valid Lua that the config loader rejects (e.g.
> `hl.permission(path, kind, "allow")` vs the wrong `mode`).

## 12.3 LSP / editor integration (do this in Phase 1)

Stubs ship with Hyprland at `/usr/share/hypr/stubs/hl.meta.lua` (verified present on this
machine). Wire into LuaLS (sumneko):

```json
// .luarc.json — repo root
{
  "workspace": {
    "library": ["/usr/share/hypr/stubs"]
  }
}
```

```json
// .vscode/settings.json
{
  "Lua.workspace.library": ["/usr/share/hypr/stubs"]
}
```

Effect: autocomplete + type-checking for every `hl.*` call, inline docs, and catch misspelled
effect names (e.g. `no_blurr`) before you boot.

## 12.4 `hyprctl` — the new toolbox

```bash
hyprctl repl                              # interactive Lua REPL (0.56+)
hyprctl eval 'hl.unbind("SUPER + O")'     # one-shot Lua
hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = 1 }))'
hyprctl config full-reload                # ground-up reload (0.56+)
hyprctl verify-config
```

`hyprctl eval` executes inside the compositor — use it to prototype a snippet, inspect state
(`hl.get_config(...)`, `hl.get_active_window()`, ...), then paste into the config.

## 12.5 Community dotfiles to crib from

| Project | URL | Why |
|---|---|---|
| cebem1nt/dotfiles | github.com/cebem1nt/dotfiles | merged the example-springs fix (PR #15499) |
| uhs-robert/dotfiles + HyprVim | github.com/uhs-robert/hyprvim | first Lua "plugin"; in-process keybind logic; `legacy-conf` branch for comparison |
| Nurysso/hecate | github.com/Nurysso/hecate | polished Lua config structure |
| acropolis914/hyprsettings | github.com/acropolis914/hyprsettings | GUI editor — Lua support pending |

## 12.6 What to keep in CI (optional, HyprFlux install pipeline)

A `review/`-adjacent GitHub Action (or pre-commit hook):

```yaml
- run: luac -p hyprland.lua
- run: Hyprland --config ~/.config/hypr/hyprland.lua --verify-config
```

This converts the migration into an ongoing safety net: every dotfile PR gets verified against
the real compositor version.

## 12.7 Version pinning

The `hl.*` API surface **moves between patch releases** (0.55 → 0.56 added
`hl.dsp.release_input_capture`, REPL, `config full-reload`). Pin:
- your target Hyprland version (HyprFlux: 0.56.2)
- the stub file used by LSP (`/usr/share/hypr/stubs/`)
- the converter version (`--check` mode)

If you upgrade Hyprland, re-run `--verify-config` — don't assume.

Next: [13-testing-validation-rollback.md](13-testing-validation-rollback.md)
