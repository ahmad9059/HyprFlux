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

## Merged Arch-Hyprland + Hyprland-Dots → base-installer + base-dots (2026-08-25)

- **base-installer/** merged into the repo (plain copy, GPL-3.0 LICENSE.md kept): install.sh pre-patched (9 bypass patches baked: welcome/proceed/AUR-helper/NVIDIA/input-group/login-manager/options-checklist/SDDM-loop/read HYP), internal refs made relative, replace_reads call removed
- **base-dots/** merged into the repo (plain copy, GPL-3.0 LICENSE.md kept): copy.sh pre-patched (resolution auto-select, SDDM wallpaper auto-yes, wallpapers auto-no, Ubuntu continue auto-yes), copy_menu.sh/lib_prompts.sh/lib_apps.sh pre-patched (auto-install/keyboard/12H-clock/express-skip/editor)
- Removed from Dots: configs/ags, config/quickshell, config/wallust (apps removed from HyprFlux) + all refs in copy.sh/scripts
- Wallpapers trimmed 37MB → 3.7MB (kept Balcony-ja.png, Night monochrome.jpg)
- `install.sh`: no more cloning base-installer; runs `$HYPRFLUX_DIR/base-installer/install.sh` (cd'd, relative paths)
- `dotfiles-main.sh`: points at merged `base-dots/copy.sh` (no git clone)
- Deleted `scripts/bypass_dialogs.sh` + `scripts/replace_reads.sh` (patches baked in)
- ISO repo: step 10 clones only HyprFlux; chroot wrapper paths → `$TARGET_HOME/HyprFlux/base-installer`; AGENTS.md/README updated
- CI: config-check.yml now also shellsyntax-checks base-installer/ + base-dots/ + triggers on their paths

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

**base-dots**
- All remaining interactive reads auto-answered (copy_phase1/waybar replace=y, restore prompts=n, backup trim=n) — install can never hang on prompts
- config/ now byte-identical to .config/ (parity enforced by CI)

**ISO repo**
- gum/fzf runtime dependency check at TUI init (fail-fast)
- Stale-mount cleanup in pre-flight (re-runs after failed installs work)
- SWAP_SIZE validated as positive integer (was: sgdig garbage input)
- chroot wrapper: A0 step injects HyprFlux zsh.sh + initial.sh (matches first-boot path);
  module env file fully aligned with dotsSetup defaults incl. REPO_DIR (was missing → modules broke)

**CI**
- config-check: base-dots/.config parity gate; RofiEmoji excluded from bash -n (known false positive)
- build-iso: shell syntax gate on airootfs scripts

## Zsh/shell install fixes (KVM/QEMU test fallout, 2026-08-25)

Test on KVM/QEMU with the merged script landed users in **bash** with **fzf missing**. Root causes + fixes:

- **BUG (fatal): `scripts/initial.sh` had `local _yay_attempts=0` at top-level scope** — `local` outside a function returns 1 and with `set -e` the script **died instantly**, so yay was never installed by initial.sh → cascading failures (no AUR helper later).
- **BUG: `scripts/zsh.sh` had `local _chsh_attempts=0` at top-level** — same bash error (non-fatal there, but the retry counter never initialized properly).
- **Cascade:** with yay missing, `install_package fzf` (Global_functions.sh ISAUR) silently failed → fzf never installed → `.zshrc:81 source <(fzf --zsh)` errored on every shell start.
- **`chsh` hardening:** zsh now added to `/etc/shells` before chsh (chsh rejects unknown shells); temp sudo permission uses a **sudoers.d drop-in** (`/etc/sudoers.d/99-hyprflux-temp`, mode 440) instead of appending to `/etc/sudoers`; **`usermod -s` fallback** if chsh fails after 5 attempts; cleanup is non-fatal (`sudo -n rm -f` then plain rm).
- **fzf/zsh packages now yay-independent:** `_install_any()` helper — installs via AUR helper, falls back to `sudo pacman -S` (zsh, lsd, mercurial, zsh-completions, fzf are all in the extra repo).
- **fzf installed BEFORE .zshrc copy** (the .zshrc sources fzf at startup).
- **`.zshrc` guarded:** `source <(fzf --zsh)` now wrapped in `if command -v fzf` (repo `.zshrc` + base-installer `assets/.zshrc`).
- `base-installer/install.sh`: `bash initial.sh` call site now guarded with `|| echo warn` so a future failure can't cascade.

## Folders renamed (2026-08-26)

- `Arch-Hyprland/` → **`base-installer/`** — merged base installer (install.sh, install-scripts/, assets/)
- `Hyprland-Dots/` → **`base-dots/`** — merged base dotfiles (copy.sh, scripts/, config/, assets/)
- All code refs updated: install.sh, base-installer/install.sh, dotfiles-main.sh (DOTS_DIR), CI workflow paths, parity gate, docs
- Internal self-names updated (lib_update.sh expected_name, archive scripts, uninstall.sh title)

## New module: 19-hardware-detect.sh (2026-08-26)

New `modules/19-hardware-detect.sh` handles all machine-to-machine setup at install time:

1. **GPU detection** (`lspci` VGA/3D/Display) → rewrites the GPU block in `UserConfigs/env-variables.lua` between `-- >>> GPU_CONFIG_START >>>` / `-- >>> GPU_CONFIG_END <<<` markers (idempotent):
   - `nvidia` → LIBVA_DRIVER_NAME=nvidia, __GLX_VENDOR_LIBRARY_NAME=nvidia, NVD_BACKEND=direct, GSK_RENDERER=ngl, GBM_BACKEND=nvidia-drm
   - `amd` → radeonsi + Mesa EGL vendor (50_mesa.json)
   - `intel` → iHD + Mesa EGL
   - hybrids (`hybrid-amd-nvidia`, `hybrid-intel-nvidia`, `hybrid-amd-intel`) → `AQ_DRM_DEVICES` built from real `/sys/class/drm/card*/device/vendor` order (preferred vendor first) + Mesa EGL
   - `none` (VM) → empty block (defaults apply)
2. **Native monitor resolution** (hyprctl → wlr-randr → xrandr → 1080p fallback, self-contained) → writes `monitors.lua` + `monitors.conf` + `Monitor_Profiles/default.*`
3. **Keyboard layout** (`localectl` → `setxkbmap` → `us`) → `kb_layout` in `UserConfigs/user-settings.lua`

- env-variables.lua (repo + base-dots) GPU section now uses markers; the old "LIVE-MACHINE ONLY" block replaced.
- Verified: sandbox tests (AMD detection, hybrid card ordering card1→card2→card0), idempotent reruns, valid Lua after generation.
- Live machine: stale hybrid block removed (only AMD card1 exists now), regenerated AMD config + monitors at native 2560x1440@165.

## Module 19 deep-hardening (2026-08-26)

Edge-case audit + fixes for `modules/19-hardware-detect.sh` so it can NEVER break an install:

**Bug fixed (critical):** hybrid `AQ_DRM_DEVICES` path builder produced `/dev/dri/card1:card2:card0` (missing prefixes) — now emits `/dev/dri/card1:/dev/dri/card2:/dev/dri/card0`.

**Bug fixed:** empty-name monitor from hyprctl (`"name":""`) shifted the field parse (mangled `output="1024"`). Now converted to FALLBACK sentinel; nameless rows are skipped (trailing wildcard fallback covers them).

**Bug fixed:** raw `"FALLBACK"` inside the `python3 -c "..."` double-quoted heredoc broke bash quoting → nameless monitors were dropped. Escaped as `\"FALLBACK\"`.

**Hardened:**
- `set -e` safety: dotsSetup sources modules inside `if source` (suspends errexit — verified) + every sub-step individually guarded with early-return 0
- No python3 dependency in file writes — awk-based marker replacement + kb_layout edit
- Atomic writes everywhere (mktemp + mv, never half-written files); cleanup trap
- Every external tool checked (`command -v`) before use: lspci, hyprctl, wlr-randr, xrandr, localectl, setxkbmap, awk, luac
- GPU detection: virtio/qxl/vmware/bochs → none (VM safe); no PCI → none; only real `/dev/dri/cardN` nodes used for AQ_DRM_DEVICES (sysfs alone not trusted)
- GPU block sanity check (only `hl.env`/comments allowed inside markers)
- Post-write Lua validation, but only self-heals if the file was valid BEFORE the write (never clobbers pre-existing user errors)
- Monitors: width/height must be positive ints; refresh clamped 30–240 else 60; scale numeric default 1.0; offsets must be signed ints; monitor names sanitized to `[a-zA-Z0-9_-]`; xrandr negative offsets (`-1920+0`) parsed; empty scale/rr/offset fields normalized
- Keyboard: layout validated `[a-zA-Z0-9_,-]` (rejects `n/a`, injection chars); awk edit safe for special chars
- `luac` missing → validation skipped gracefully; unreadable files → skipped with warn
- All failures return 0 (never abort dotsSetup); verified exit 0 across: AMD, NVIDIA-mock, hybrid-mock, virtio-mock, no-tools, corrupted env file, read-only file, missing kb_layout line, no-luac, idempotent reruns

## Double-copy eliminated (2026-08-26)

**Found:** config was deployed TWICE — base-installer's `dotfiles-main.sh` ran `base-dots/copy.sh` (copying `base-dots/config/` → `~/.config/`), then dotsSetup module 02 deleted those dirs and copied `.config/` again. Since `base-dots/config` ≡ `.config/` (CI parity gate), the first copy was pure waste, and copy.sh's waybar/rofi/sddm side-effects referenced dead JaKooLit paths.

**Fix:**
- `dotfiles-main.sh` now only VERIFIES the merged base-dots checkout (presence + drift warning) and hands off to module 02 — **module 02 is the single config deployer**
- module 02 gained explicit `chmod +x` for scripts/UserScripts/initial-boot.sh/tmuxifier layouts (belt-and-suspenders, since copy.sh's chmod no longer runs)
- `base-dots/copy.sh` kept as a standalone manual tool only
- Docs updated (ARCHITECTURE, ISO wrapper A15 comment)

## Single package step (2026-08-26)

**Found:** packages were installed TWICE — once by `base-installer/install-scripts/01-hypr-pkgs.sh`, again by HyprFlux modules 03/16/17 (required + optional + AI tools).

**Fix — ONE package step in the base installer:**
- All packages merged into `base-installer/install-scripts/01-hypr-pkgs.sh`:
  - `hypr_package` + `hypr_package_2` (base ecosystem)
  - HyprFlux-required pacman pkgs (was module 03): foot lsd bat neovim firefox tmux yazi zoxide qt6-5compat chromium npm plymouth rclone lazygit github-cli networkmanager power-profiles-daemon
  - Default apps (was module 17 — **no longer optional**, installed unconditionally): alacritty tldr obs-studio vlc luacheck luarocks hyprpicker obsidian noto-fonts-emoji tuned ttf-noto-nerd noto-fonts
  - AUR pkgs (was 03/16/17): awww-git mpvpaper waybar-git visual-studio-code-bin 64gram-desktop-bin vesktop foliate localsend-bin tuxedo-bin claude-code opencode-bin openai-codex-bin
- Modules deleted: `03-packages.sh`, `16-ai-tools.sh`, `17-optional-packages.sh`
- Modules renumbered 01–16 (no gaps): backup, dotfiles, neovim, themes, waybar, sddm, gtk, grub, plymouth, tmux, zsh, wallpapers, webapps, bibata, monitors, hardware-detect
- Chroot wrapper: removed 17-optional skip + AI_TOOLS env var
- Every install step now completes ONCE and is never repeated

## GRUB + Plymouth theme hardening (2026-08-26)

Both boot-theme modules rewritten to install fully and handle every edge case:

**modules/08-grub.sh (HyprFlux GRUB theme):**
- GRUB absent (no grub-install/grub-mkconfig) → clean skip
- Archive validated before extraction (tar -tJf, corrupt → skip)
- Fresh extraction every run (rm -rf temp dir first — no stale dirs)
- **Removes any existing HyprFlux theme first** (idempotent re-runs)
- Runs bundled install.sh as root; on failure → **manual fallback** (copies theme files directly)
- **Verifies installation** (theme.txt present in /usr/share/grub/themes/HyprFlux) — not just "script ran"
- **Wires/verifies GRUB_THEME=** in /etc/default/grub (replaces old value, no duplicates)
- Regenerates grub.cfg explicitly; non-fatal if grub-mkconfig missing/fails
- Never aborts install (cosmetic step — always returns 0); temp cleanup

**modules/09-plymouth.sh (HyprFlux Plymouth theme):**
- plymouth package installed if missing (non-fatal)
- Archive validated; fresh extraction; **theme validated** (requires .plymouth + .script)
- **Removes previous hyprflux theme before install**; verifies copy landed
- **mkinitcpio HOOKS duplicate-safe**: only adds `plymouth` if not already in the HOOKS=( ) list (word-in-comment doesn't count)
- **Sets theme via plymouth-set-default-theme AND verifies plymouthd.conf Theme= line**; direct plymouthd.conf fallback write
- **GRUB_CMDLINE_LINUX_DEFAULT token-safe**: adds `quiet`/`splash` individually (all 4 combinations tested, no duplicate tokens)
- mkinitcpio -P rebuild; all steps non-fatal

Tested: corrupt archive, missing archive, no-GRUB, no-sudo-terminal (graceful), full happy path with mocks, idempotent re-runs on real machine (themes re-verified present), HOOKS 3-case logic, GRUB token 4-case logic.

## Cross-machine install hardening (2026-08-26)

Deep audit to make the install work smoothly on ANY hardware, not just the maintainer's machine. Found + fixed:

**Machine-specific leaks in shipped configs:**
- `qt5ct.conf` / `qt6ct.conf`: hardcoded `/home/ahmad/` color_scheme_path → `__HYPRFLUX_HOME__` placeholder; module 02 substitutes the real `$HOME` at install (qt5ct reads the path literally, no env expansion)
- `laptops.lua`: ASUS-only binds (rog-control-center, asusctl) now guarded by `command -v` checks — never fire on non-ASUS
- Waybar `temperature` hwmon-path: hardcoded `hwmon1` → module 16 now auto-detects a real thermal sensor (k10temp/coretemp > acpitz > thermal_zone > any hwmon) and rewrites the block (idempotent, JSONC-safe)
- hyprlock bundled fonts (SF Pro Display) were never registered with fontconfig → added `~/.config/fontconfig/fonts.conf` registering `~/.config/hypr/hyprlock/Fonts` (verified fc-list picks them up)
- keybinds SUPER+K (kdenlive) + SUPER+M (freedownloadmanager) referenced apps NOT in the package list → added to merged list

**Package/installer failure resilience:**
- `install.sh`: pacman keyring init/populate before first `-Syu` (fresh Arch installs fail with "GPG keys are outdated" otherwise) + refresh-keys retry
- `Global_functions.sh`: `ISAUR` falls back to `sudo pacman` when no AUR helper exists — `install_package`/`install_package_f` no longer run bare `-Q`/`-S` (command-not-found) when yay is missing
- `yay.sh`: final `-Syu` guarded with the same fallback (was: empty ISAUR → command not found → exit 1 → whole installer died)
- Verified all 93 merged packages parse cleanly; every keybind/waybar/runtime binary maps to an installed package

**Verified machine-agnostic:** ISO installer (TTY width auto, keyring init, both microcodes, virtio/qxl detection), SDDM session dir, initial-boot.sh ($HOME-based), Volume/Brightness/Battery scripts (default devices), startup execs, window-rules classes (no-op when app absent).

## awww: prebuilt binary replaces source build (2026-08-26)

User hit: `awww-git` (AUR) failed to install — it's a Rust source build needing cargo+dav1d+scdoc; slow (~3min) and fragile on machines without the toolchain. No prebuilt awww exists upstream (codeberg, source-only releases).

**Fix:**
- Built awww 0.12.1 + awww-daemon once (verified compiles, 8.4MB+451KB binaries) → packaged as **`utilities/awww-prebuilt.tar.xz`** (2.1MB)
- `modules/12-wallpapers.sh`: new step installs the prebuilt binaries to `/usr/local/bin` (install -Dm755); falls back to `yay awww-git` only if the archive is missing/unusable
- `base-installer/install-scripts/01-hypr-pkgs.sh`: awww-git **removed** from the AUR build array (only comments reference it); added AUR **build-tools pre-install** (cmake meson ninja scdoc rust dav1d catch2) so remaining source-built AUR pkgs (waybar-git, mpvpaper) compile reliably
- Verified: archive integrity, sandbox module run (prebuilt path works), live install pending sudo

## Unified logging system (2026-08-26)

All logs now live in ONE place: **`~/HyprFlux/logs/`**

| Path | Contents |
|------|----------|
| `logs/install.log` | main installer (install.sh) output |
| `logs/dotsSetup.log` | dotsSetup module output |
| `logs/installer/*.log` | base-installer script logs (00-base, yay, 01-hypr-pkgs, pipewire, fonts, sddm, zsh, …) |
| `logs/copy/*.log` | base-dots copy logs |

**Changes:**
- `lib/common.sh`: new `HYPRFLUX_LOGS_DIR` (default `$HOME/HyprFlux/logs`, overridable) — single source for all log paths
- `install.sh` + `dotsSetup.sh`: `hyprflux_log/` → `$HYPRFLUX_LOGS_DIR/{install,dotsSetup}.log`
- `base-installer/install.sh` + all 21 install-scripts + `scripts/zsh.sh`: `Install-Logs/` → `$HYPRFLUX_LOGS_DIR/installer/` (yay/paru build logs too)
- `base-dots/copy.sh` + `lib_update.sh`: `Copy-Logs/` → `$HYPRFLUX_LOGS_DIR/copy/`
- ISO chroot wrapper: `Install-Logs` → `${TARGET_HOME}/HyprFlux/logs/installer` (+ chown)
- Old `hyprflux_log/` and per-repo `Install-Logs/`/`Copy-Logs/` folders eliminated

## Current state

- **Live session runs the Lua config** (verified `dispatcher: __lua`)
- Repo ↔ live in sync for all managed configs (rofi, swaync, hypr, waybar, scripts)
- Working tree clean, all changes committed