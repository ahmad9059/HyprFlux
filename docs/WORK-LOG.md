# HyprFlux Work Log

Complete log of all work done on this repository. See `docs/plan/` for the migration details and `docs/plan/progress.md` for the phase-by-phase migration log.

---

## 1. Migration: hyprlang (.conf) → Lua (Hyprland ≥ 0.55)

**Why:** Hyprland 0.56.2 (installed) dropped hyprlang — a Lua config is mandatory; the old `.conf` shows a deprecation notice and is ignored.

**What was done:**
- Full config converted to `hyprland.lua` (entrypoint) + modular files under `.config/hypr/configs/` and `.config/hypr/UserConfigs/`
- Migration fully documented in `docs/plan/` (docs 00–16 + 99-appendix): syntax crash course, hyprlang→Lua mapping, keybinds, monitors/workspaces, window rules, autostart/env, animations/devices, testing, advanced patterns, troubleshooting
- Legacy config was archived as `~/.config/hypr_old/` — **removed 2026-08-26** (Lua is the only config format; no rollback path needed)
- **Verified live:** `dispatcher: __lua`, 152 binds, all options `set: true`, `hyprctl eval` works
- Gotchas discovered (documented in 16-troubleshooting):
  - `hyprctl dispatch <old-hyprlang-string>` is broken in Lua mode (parsed as Lua) — use `hl.dsp.*` / `hyprctl eval`
  - `hl.monitor()` eval verified live for runtime monitor changes (60↔165 Hz round-trip)

## 2. Color centralization (single source of truth)

- **`hyprflux-colors/hyprflux-colors.conf`** (146 vars: core, lock, term, bar, notif, logout, rofi, …) is the ONE palette source
- **`utilities/sync-colors.sh`** regenerates from it:
  - `hyprflux-colors.lua` (Hyprland)
  - `rofi/hyprflux-colors.rasi` (rofi) — was `rofi/wallust/`, moved out of `wallust/` (wallust layer removed)
  - `waybar/hyprflux-colors.css` (waybar, plus injected color blocks into swaync/wlogout — GTK4 cannot import)
  - `kitty/kitty-colors.conf`, `foot/colors.ini`
- CI gates that generated files are up to date

## 3. SwayNC (SUPER+N)

- All themed PNG images and `images/`/`icons/` dirs removed (Papirus `dialog-*`, `audio-*`, `display-brightness` etc.) — GTK icons used instead
- **Height: 90% of screen** (`control-center-height: 1296` on 1440p, width 360)
- **Scrollbar hidden** (GTK4 hierarchy `scrollbar > range > trough > slider` made transparent/0-size; wheel scrolling still works)
- Colors verified pixel-exact solid `#0e0e16` via ImageMagick analysis
- ⚠️ **Experiment reverted:** a full visual redesign (solid background, compact entries, purple accents) was made then **undone at user request** — swaync keeps the original/previous look with only the 90% height + hidden scrollbar changes

## 4. Rofi

- **Wallust layer removed:** generated palette moved `rofi/wallust/hyprflux-colors.rasi` → `rofi/hyprflux-colors.rasi`; `master-config.rasi` `@theme` path + `sync-colors.sh` updated; `wallust/` dirs deleted (repo + live)
- **Orphans deleted:** `config-zsh-theme.rasi` (ZshChangeTheme removed), `config-rofi-theme.rasi` (unused), `Tak0-Autodispatch.sh` (dead), `RainbowBorders.sh.bak` (dead backup)
- **Useless scripts removed:** `RofiSearch.sh` + `config-search.rasi` (SUPER+S bind was commented out), `0-shared-fonts.rasi` (imported nowhere)
- Remaining rofi scripts all wired: KeyBinds, Animations, Emoji, Clipboard, Calc, Beats, WallpaperSelect/Effects, MonitorProfiles (via Quick Settings), Quick Settings
- ⚠️ **Experiment reverted:** a compact-theme pass (smaller paddings/spacings/icons, window 44%→40%) was applied then **undone at user request** — original values restored exactly (verified against git HEAD)

## 5. Scripts: fixed / added / removed

**Added:**
- `GitRepoClone.sh` (new UserScript, SUPER+G) — clones GitHub repos with start/success/failure(+reason) notifications

**Fixed:**
- `ChangeLayout.sh` — was clobbering SUPER+K (Kdenlive) via runtime unbind/rebind; now a **pure layout toggle**; cycles Dwindle → Master → Scrolling
- `GameMode.sh` — state-based toggle (state file in `$XDG_RUNTIME_DIR`), restores exact previous values; wallpaper kill/restart kept per user; disable no longer runs Refresh.sh
- `Brightness.sh` — MAX capped at **95%** (user set after 100% test), MIN 5
- `Weather.py` — rewritten on **wttr.in** (stdlib only, no scraping/pyquery); JSON + hyprlock cache preserved
- `refresh-rate.sh` — uses `hl.monitor` eval (verified 60↔165 Hz round-trip)
- `KeyHints.sh` — rebuilt as curated cheat sheet (~101 pairs, grouped, verified against config)
- `RofiEmoji.sh` — known false positive: fails `bash -n` but works (self-extracting emoji data after `exit`)

**Removed:**
- `DarkLight`, `RofiThemeSelector*`, `Kitty_themes`, `ZshChangeTheme`, `Polkit-NixOS`, `UptimeNixOS`
- Jellyfin, `sddm_wallpaper.sh.bak`, duplicate `Tak0-Autodispatch`, `WaybarStyles.sh`/`WaybarLayout.sh` (switchers — single theme/layout remains)
- **quickshell/ags fully removed** (incl. plan doc 15), `qml_color.json` generation from sync-colors.sh

## 6. Keybinds (user-keybinds.lua / keybinds.lua)

- **SUPER+J** → `window.cycle_next()` (any layout); removed broken cyclenext bind
- **SUPER+K / CTRL+D / I / CTRL+RETURN** → master-guarded via new `layoutMsgIf(layout, msg)` helper (no error notifications)
- **SUPER+O** → dwindle-guarded `togglesplit`
- **SUPER+SHIFT+L** → 3-layout cycle (Dwindle/Master/Scrolling)
- **SUPER+G** → GitRepoClone, **SUPER+SHIFT+H** → KeyHints, **SUPER+SHIFT+E** → Quick Settings (+ "Check for HyprFlux Updates")
- Kdenlive SUPER+K restored (survives layout toggles)

## 7. Window rules (UserConfigs/window-rules.lua)

Reorganized routing (97 + 2 layer rules):
- ws1 = dev (VSCode `code` class fix, tmuxifier, Chrome-for-Testing → **6 silent special-case windows**)
- ws2 = browser (chromium tagged `+browser`), ws3 = files, ws4 = IM + screenshare
- ws6 = games (gamestore merged), ws9 = VMs, ws10 = obsidian
- special:nyx = vesktop/discord/spotify
- media + kitty free (no workspace assignment)

## 8. Waybar

- `waybar-git` (chaotic-aur) required for workspace-click Lua dispatch (PR #5013) — user confirmed fixed
- `threshold-red` CSS removed (`#battery.critical`, `#temperature.critical`) — also fixed a stray `*/` CSS parse break
- Temperature format `{icon} {temperatureC}°C`; weather `{icon} {temp}°` (single space)
- Battery charge capped 95% (user request)
- Real files, not symlinks: `config` = copy of `configs/HyprFlux-Default-Laptop`; `style.css` imports `style/HyprFlux-Default.css`
- Live `waybar/Modules` differs from repo (user's hwmon `hwmon5`, critical-threshold 96) — intentional, machine-specific

## 9. CI (`.github/workflows/config-check.yml`)

- Arch container: `luac` compile-check all Lua + `Hyprland --verify-config`
- `sync-colors.sh` up-to-date gate
- **Fix applied:** `XDG_RUNTIME_DIR` must be exported before Hyprland verify (`/tmp/hypr-runtime`, mode 700) — validated locally via `env -i` simulation (`config ok`, exit 0)

## 10. Machine-specific (live-only, NOT in repo — by design)

- `~/.config/hypr/scripts/initial-boot.sh` — one-shot first-boot setup (marker-gated), referenced by `hyprland.lua`
- `~/.config/hypr/scripts/refresh-rate.sh` — 165Hz AC / 60Hz battery daemon, run via `hypr-refresh-rate.service` (systemd user unit)
- These reference local hardware (`eDP-1`, `AC0`); live-only keeps the distro generic

## 11. Modules

- Renumbered 01–18; `initial-boot.sh` refs cleaned (`HyprFlux-Default.css`)

---

## Reverted / abandoned experiments (kept for reference)

| Change | Applied | Reverted | Reason |
|---|---|---|---|
| SwayNC visual redesign (solid bg, compact entries, purple accents) | 2026-08 | 2026-08 | User wanted the original look/colors |
| Rofi compact theme (padding/spacing/icons, 40% width) | 2026-08 | 2026-08 | User reverted; kept original spacing |

## Merged Arch-Hyprland + Hyprland-Dots (2026-08-25)

- **Arch-Hyprland/** merged into the repo (plain copy, GPL-3.0 LICENSE.md kept): install.sh pre-patched (9 bypass patches baked: welcome/proceed/AUR-helper/NVIDIA/input-group/login-manager/options-checklist/SDDM-loop/read HYP), internal refs made relative, replace_reads call removed
- **Hyprland-Dots/** merged into the repo (plain copy, GPL-3.0 LICENSE.md kept): copy.sh pre-patched (resolution auto-select, SDDM wallpaper auto-yes, wallpapers auto-no, Ubuntu continue auto-yes), copy_menu.sh/lib_prompts.sh/lib_apps.sh pre-patched (auto-install/keyboard/12H-clock/express-skip/editor)
- Removed from Dots: configs/ags, config/quickshell, config/wallust (apps removed from HyprFlux) + all refs in copy.sh/scripts
- Wallpapers trimmed 37MB → 3.7MB (kept Balcony-ja.png, Night monochrome.jpg)
- `install.sh`: no more cloning Arch-Hyprland; runs `$HYPRFLUX_DIR/Arch-Hyprland/install.sh` (cd'd, relative paths)
- `dotfiles-main.sh`: points at merged `Hyprland-Dots/copy.sh` (no git clone)
- Deleted `scripts/bypass_dialogs.sh` + `scripts/replace_reads.sh` (patches baked in)
- ISO repo: step 10 clones only HyprFlux; chroot wrapper paths → `$TARGET_HOME/HyprFlux/Arch-Hyprland`; AGENTS.md/README updated
- CI: config-check.yml now also shellsyntax-checks Arch-Hyprland/ + Hyprland-Dots/ + triggers on their paths

## Production-hardening audit (2026-08-25)

Deep edge-case audit + fixes across the whole install pipeline:

**Main install flow**
- `install.sh`: HYPRFLUX_DIR now pins to the actual clone location (SCRIPT_DIR) — custom checkout paths no longer break; `dotsSetup.sh` REPO_DIR same fix
- `dotsSetup.sh`: waybar defaults fixed to real HyprFlux paths (HyprFlux-Default.css / HyprFlux-Default-Laptop)
- module 06-waybar: no longer symlinks (module 02 ships real files) — now verify + reload only
- module 15-bibata: writes `env-variables.lua` (Lua) instead of dead ENVariables.conf
- module 03: added **awww-git + mpvpaper** (wallpaper pipeline was broken — awww started by startup-apps.lua but never installed), **networkmanager** (was only in ISO pacstrap, missing on manual path), **power-profiles-daemon**; **waybar-git** moved here (stable waybar removed from 01-hypr-pkgs — workspace-click Lua dispatch requires waybar-git)
- module 17: tuned added (Toggle-tuned.sh)
- `scripts/initial.sh`: yay build retry capped at 5 + yay-bin fallback (was infinite loop)
- `scripts/zsh.sh`: chsh retry capped at 5 (was infinite loop)
- Machine-specific leaks removed from distro configs (commented with restore notes):
  env-variables.lua AQ_DRM_DEVICES/Mesa-EGL block; window-rules Chrome-for-Testing rule;
  startup-apps.lua hypr-refresh-rate.service restart. laptops.lua touchpad kept as
  no-op-if-absent hl.device()

**Hyprland-Dots**
- All remaining interactive reads auto-answered (copy_phase1/waybar replace=y, restore prompts=n, backup trim=n) — install can never hang on prompts
- config/ now byte-identical to .config/ (parity enforced by CI)

**ISO repo**
- gum/fzf runtime dependency check at TUI init (fail-fast)
- Stale-mount cleanup in pre-flight (re-runs after failed installs work)
- SWAP_SIZE validated as positive integer (was: sgdig garbage input)
- chroot wrapper: A0 step injects HyprFlux zsh.sh + initial.sh (matches first-boot path);
  module env file fully aligned with dotsSetup defaults incl. REPO_DIR (was missing → modules broke)

**CI**
- config-check: Hyprland-Dots/.config parity gate; RofiEmoji excluded from bash -n (known false positive)
- build-iso: shell syntax gate on airootfs scripts

## Zsh/shell install fixes (KVM/QEMU test fallout, 2026-08-25)

Test on KVM/QEMU with the merged script landed users in **bash** with **fzf missing**. Root causes + fixes:

- **BUG (fatal): `scripts/initial.sh` had `local _yay_attempts=0` at top-level scope** — `local` outside a function returns 1 and with `set -e` the script **died instantly**, so yay was never installed by initial.sh → cascading failures (no AUR helper later).
- **BUG: `scripts/zsh.sh` had `local _chsh_attempts=0` at top-level** — same bash error (non-fatal there, but the retry counter never initialized properly).
- **Cascade:** with yay missing, `install_package fzf` (Global_functions.sh ISAUR) silently failed → fzf never installed → `.zshrc:81 source <(fzf --zsh)` errored on every shell start.
- **`chsh` hardening:** zsh now added to `/etc/shells` before chsh (chsh rejects unknown shells); temp sudo permission uses a **sudoers.d drop-in** (`/etc/sudoers.d/99-hyprflux-temp`, mode 440) instead of appending to `/etc/sudoers`; **`usermod -s` fallback** if chsh fails after 5 attempts; cleanup is non-fatal (`sudo -n rm -f` then plain rm).
- **fzf/zsh packages now yay-independent:** `_install_any()` helper — installs via AUR helper, falls back to `sudo pacman -S` (zsh, lsd, mercurial, zsh-completions, fzf are all in the extra repo).
- **fzf installed BEFORE .zshrc copy** (the .zshrc sources fzf at startup).
- **`.zshrc` guarded:** `source <(fzf --zsh)` now wrapped in `if command -v fzf` (repo `.zshrc` + Arch-Hyprland `assets/.zshrc`).
- `Arch-Hyprland/install.sh`: `bash initial.sh` call site now guarded with `|| echo warn` so a future failure can't cascade.

## Current state

- **Live session runs the Lua config** (verified `dispatcher: __lua`)
- Repo ↔ live in sync for all managed configs (rofi, swaync, hypr, waybar, scripts)
- Working tree clean, all changes committed