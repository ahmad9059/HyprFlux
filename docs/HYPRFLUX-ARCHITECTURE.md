# HyprFlux — Complete Architecture Report (Deep Dive)

**Date:** 2026-08-24
**Scope:** Full source analysis of HyprFlux, HyprFlux-ISO, base-installer and related repos.
**Level of detail:** file-by-file architecture, both installation paths, every component.

---

# PART 1 — ECOSYSTEM OVERVIEW

## 1.1 What HyprFlux Is

HyprFlux is a complete **Arch Linux desktop operating system project** built around the Hyprland Wayland compositor. It is not a single dotfiles repo — it is a platform with four layers:

| Layer | What it provides |
|-------|-----------------|
| **ISO layer** | Custom `archiso`-based live ISO with HyprFlux branding, GRUB/Syslinux/Plymouth boot pipeline, and a TUI installer |
| **Installer layer** | Two converging paths (ISO installer + direct script) that provision a full desktop from a bare Arch system |
| **Desktop layer** | Maintained Hyprland Lua config, Waybar, Rofi, SwayNC, Wlogout, Kitty, Foot, Ghostty, Cava, Yazi, Kvantum, Qt5/6ct theming |
| **Identity layer** | Single-source color palette, GTK theme (HyprFlux-Compact), SDDM theme, GRUB theme, Plymouth theme, cursors, wallpapers, logos |

The stated goal (from README): *"start from a fresh Arch installation and end up with a polished, consistent, production-ready Hyprland system without piecing everything together manually."*

## 1.2 The Repo Ecosystem (6 repos)

| Repo | Role | URL |
|------|------|-----|
| **HyprFlux** (this repo) | Main: desktop configs, install entrypoints, 18 setup modules, assets, docs | `github.com/ahmad9059/HyprFlux` |
| **HyprFlux-ISO** | archiso profile, TUI installer, boot configs, CI ISO builds | `github.com/ahmad9059/HyprFlux-ISO` |
| **base-installer** *(merged 2026-08-25)* | Base installer (upstream-derived) — now a subdir of HyprFlux: pre-patched `install.sh` + 24 `install-scripts/` | `base-installer/` in this repo |
| **base-dots** *(merged 2026-08-25)* | Base dotfiles (upstream-derived) — now a subdir of HyprFlux, pre-patched, no clone at install time | `base-dots/` in this repo |
| **nvim** | Separate maintained Neovim config (cloned by module 04-neovim) | `github.com/ahmad9059/nvim` |
| **wallpapers-bank** | Wallpaper collection (cloned by module 13-wallpapers) | `github.com/ahmad9059/wallpapers-bank` |

**Dependency direction:**

```
HyprFlux-ISO ──clones──▶ HyprFlux (contains base-installer/ + base-dots/ merged)
                              │
                              ├──▶ nvim (ahmad9059)
                              └──▶ wallpapers-bank (ahmad9059)
```

The ISO does not bake HyprFlux into the image — it **clones only HyprFlux** into the target system during install, then runs the exact same `install.sh` used by the manual path on first boot. base-installer and base-dots are merged subdirs; nothing else is cloned at install time.

## 1.3 System Requirements

- Base: Arch Linux; Architecture: `x86_64`
- RAM: 4 GB minimum, 8 GB+ recommended
- Storage: 10 GB minimum free (ISO installer warns 20 GB+)
- Network: active internet (all repos + packages downloaded at install time)
- Recommended starting point: fresh Arch, working internet, sudo-capable user, `curl`/`git`

---

# PART 2 — MAIN REPO (HyprFlux) — TOP-LEVEL LAYOUT

## 2.1 Repository Tree (annotated)

```text
HyprFlux/
├── install.sh                 # Top-level install entry point (~170 lines)
├── dotsSetup.sh               # Modular dotfiles orchestrator (~130 lines)
├── lib/                       # Shared libraries (sourced, never executed)
│   ├── common.sh              # Colors, logging, sudo, prompts, SKIP_MODULES
│   ├── git.sh                 # ensure_repo + clone_with_retry
│   └── packages.sh            # pacman/yay install with retry + verification
├── modules/                   # 18 numbered setup units (01–18), sourced in order
├── scripts/                   # Installer helper scripts (patch/automation tools)
│   ├── initial.sh             # Chaotic-AUR + yay bootstrap
│   ├── zsh.sh                 # Zsh + Oh-My-Zsh non-interactive install
│   └── ai-commit-msg          # AI commit message helper
├── config/
│   └── webapps.conf           # PWA list: Name|URL|IconName
├── utilities/                 # Bundled binary assets
│   ├── HyprFlux-1080p.tar.xz  # GRUB theme archive
│   ├── hyprflux-plymouth.tar.xz
│   ├── HyprFlux-sddm-theme/   # SDDM QML theme (Main.qml, theme.conf, Assets/)
│   ├── Bibata-Modern-Classic.tar.xz   # hyprcursor theme
│   ├── Future-black-cursors.tar.gz    # X cursor theme
│   ├── sync-colors.sh         # Color generator (single source of truth)
│   ├── logos/                 # SVG/PNG logos
│   └── applications/          # .desktop assets
├── .config/                   # THE maintained desktop environment
├── .themes/                   # HyprFlux-Compact + Material-DeepOcean-BL (GTK)
├── .tmux.conf                 # Tmux config
├── .tmuxifier/layouts/        # web-dev.session.sh etc.
├── .zshrc                     # Zsh config
├── docs/
│   ├── plan/                  # Migration docs 00–16 + 99-appendix + progress.md
│   ├── WORK-LOG.md            # Chronological work log
│   └── HYPRFLUX-ARCHITECTURE.md  # This document
├── review/                    # Screenshots + HyprFlux.svg logo
├── CODE_OF_CONDUCT.md, CONTRIBUTING.md, SECURITY.md, LICENSE (MIT)
├── .luarc.json                # Lua language server config for hyprlang-lua
└── .github/workflows/config-check.yml  # CI
```

## 2.2 `install.sh` — Manual Path Entry Point (full detail)

**Purpose:** the single entry point used by both installation paths (direct + ISO first-boot).

### Mode A — curl-pipe bootstrap

Detects it is running from a pipe (no real directory):

```bash
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd 2>/dev/null || echo "")"
if [[ -z "$_script_dir" ]] || [[ "$_script_dir" == "/dev/fd" ]] ... || [[ ! -f "$_script_dir/lib/common.sh" ]]; then
```

When `BASH_SOURCE[0]` resolves to `/dev/fd/*` (pipe from `sh <(curl ...)`), it:
1. Installs `git` via `sudo pacman -Sy --noconfirm git` if missing
2. Clones (or `git pull --ff-only` if `$HOME/HyprFlux/.git` exists) the repo from `HYPRFLUX_REPO` (default `https://github.com/ahmad9059/HyprFlux.git`)
3. `exec bash "$HYPRFLUX_DIR/install.sh"` — re-executes from the real clone

This makes the one-liner `sh <(curl -fsSL https://hyprflux.dev/install)` fully self-contained.

### Mode B — local run

1. Sources `lib/common.sh` + `lib/git.sh`
2. `setup_logging "$HOME/hyprflux_log/install.log"` — all output teed to log
3. Prints the ASCII "HYPRFLUX" banner + "ahmad9059 ✻" separator
4. `setup_sudo` — asks once, keeps alive every 30s, traps cleanup
5. `sudo pacman -Syu --noconfirm git vim` — full system update

### The main flow (4 steps)

```
Step 1  Run merged base-installer install.sh (pre-patched, fully automated)
        ARCH_HYPRLAND_DIR="$HYPRFLUX_DIR/base-installer"    # merged subdir, no clone
        - All 9 whiptail bypass patches are BAKED IN (welcome/proceed/AUR helper/
          NVIDIA/input-group/login-manager/options-checklist/SDDM-loop/read HYP)
        - (cd "$ARCH_HYPRLAND_DIR" && bash install.sh)     # MUST cd: relative install-scripts/
        - install.sh copies HyprFlux's scripts/zsh.sh over its own, runs
          scripts/initial.sh (Chaotic-AUR + yay) via relative $HYPRFLUX_DIR
        - scripts/bypass_dialogs.sh + replace_reads.sh were DELETED (patches baked in)

Step 3  Run HyprFlux dotsSetup.sh
        ensure_repo "$HYPRFLUX_REPO" "$HYPRFLUX_DIR" --depth=1   (self, already present)
        bash "$HYPRFLUX_DIR/dotsSetup.sh"

Step 4  Reboot prompt (ask_yes_no)
        - If HYPRFLUX_ISO_MODE=1 env set: skip prompt ("reboot handled by installer")
        - Else: ask "Do you want to reboot now?" → sudo reboot or defer
```

## 2.3 `dotsSetup.sh` — Modular Orchestrator (full detail)

**Design:** modules are **sourced** (not subprocesses) so they share all variables/functions from the three libs. Sourcing order is filename-sorted (`[0-9]*.sh`). A module signals skip via `should_skip "name" && return 0` which honors the `SKIP_MODULES` env var (comma-separated).

**Flow:**
1. Resolve `SCRIPT_DIR`
2. Source `lib/common.sh`, `lib/packages.sh`, `lib/git.sh`
3. `setup_logging "$HOME/hyprflux_log/dotsSetup.log"` (single tee — a previous double-tee bug was fixed)
4. `setup_sudo`
5. Define ~30 config variables, **all overridable via environment**:

| Variable | Default | Purpose |
|----------|---------|---------|
| `REPO_URL` | `https://github.com/ahmad9059/HyprFlux.git` | self repo |
| `REPO_URL_NVIM` | `https://github.com/ahmad9059/nvim` | nvim config |
| `TMUXIFIER_REPO` | `https://github.com/jimeh/tmuxifier.git` | tmuxifier |
| `REPO_DIR` | `$HOME/HyprFlux` | repo path (bugfix: no more mixed `$HOME/HyprFlux`) |
| `BACKUP_DIR` | `$HOME/dotfiles_backup` | backup target |
| `WAYBAR_STYLE_TARGET` | `~/.config/waybar/style.css` | waybar style link target |
| `WAYBAR_LAYOUT_TARGET` | `~/.config/waybar/config` | waybar config link target |
| `CUSTOM_WAYBAR_STYLE` | `~/.config/waybar/style/Catppuccin Mocha Custom.css` | source style |
| `CUSTOM_WAYBAR_LAYOUT` | `~/.config/waybar/configs/[TOP] Default Laptop` | source layout |
| `SDDM_THEME_NAME/SOURCE/DEST/CONF` | HyprFlux-sddm-theme, `utilities/…`, `/usr/share/sddm/themes/…`, `/etc/sddm.conf` | SDDM |
| `GRUB_THEME_ARCHIVE/DIR` | `utilities/HyprFlux-1080p.tar.xz`, `/tmp/hyprflux-grub` | GRUB |
| `DESKTOP_DIR/ICON_DIR/BROWSER/WEBAPPS_CONF` | `~/.local/share/applications`, `~/.local/share/icons/apps`, `chromium`, `config/webapps.conf` | webapps |
| `AI_TOOLS_AUR_PACKAGES` | `claude-code opencode-bin openai-codex-bin` | AI tools |
| `WALLPAPER_REPO/DIR` | `wallpapers-bank`, `~/Pictures/wallpapers` | wallpapers |
| `PLYMOUTH_*` | `utilities/hyprflux-plymouth.tar.xz`, name `hyprflux` | plymouth |
| `CURSOR_SIZE` | `24` (unified — was 20 vs 24 inconsistency bug) | cursors |
| `BIBATA_CURSOR_URL` | LOSEARDES77 Bibata hyprcursor release | fallback download |
| `GTK_THEME/ICON_THEME/CURSOR_THEME/FONT_NAME` | HyprFlux-Compact / Papirus-Dark / Future-black Cursors / Adwaita Sans 11 | GTK |

6. Iterate `modules/[0-9]*.sh`, `source` each, count success/failure, print summary.

---

# PART 3 — MAIN REPO: THE 18 MODULES (full detail)

## 3.1 modules/01-backup.sh

- Skips if `SKIP_MODULES` contains `backup`
- Removes existing `$BACKUP_DIR` (`~/dotfiles_backup`) then recreates it
- Copies (only if present): `~/.config` (whole dir), `~/.zshrc`, `~/.tmux.conf`

## 3.2 modules/02-dotfiles.sh

- Removes old config folders: for each `$REPO_DIR/.config/*` folder, `rm -rf ~/.config/<name>` if it exists (prevents stale leftovers)
- Copies `$REPO_DIR/.config/*` → `~/.config/`, plus `~/.zshrc`, `~/.tmux.conf`
- This is why the repo's `.config` must stay complete and self-consistent

## 3.3 modules/03-packages.sh

Required pacman packages:

```
foot lsd bat neovim firefox tmux yazi zoxide qt6-5compat chromium npm plymouth rclone lazygit github-cli
```

Installed via `install_pacman 5 "${REQUIRED_PACKAGES[@]}"` (5 retries). The AUR array is intentionally empty (placeholder; the empty-array guard in `install_yay` prevents a useless retry loop).

## 3.4 modules/04-neovim.sh

- `rm -rf ~/.config/nvim`, `git clone $REPO_URL_NVIM ~/.config/nvim`
- If `nvim` binary exists: `nvim --headless -c 'qa'` (first-run Lazy bootstrap) then `nvim --headless -c 'Lazy sync' -c 'qa'` (installs plugins + Mason tools)

## 3.5 modules/05-themes.sh

- Copies `.themes/*` → `~/.themes/` (HyprFlux-Compact, Material-DeepOcean-BL)
- Papirus: `pacman -S papirus-icon-theme papirus-folders`, then `papirus-folders -C cyan --theme Papirus-Dark`
- Cursors: extracts `utilities/Future-black-cursors.tar.gz` → `~/.icons/`

## 3.6 modules/06-waybar.sh

- **Bugfix note in file:** checks BOTH style and layout exist before symlinking
- `ln -sf CUSTOM_WAYBAR_LAYOUT WAYBAR_LAYOUT_TARGET` and `ln -sf CUSTOM_WAYBAR_STYLE WAYBAR_STYLE_TARGET`
- If waybar running: `pkill -SIGUSR2 waybar` (reload)

## 3.7 modules/07-sddm.sh

- `sudo cp -r utilities/HyprFlux-sddm-theme → /usr/share/sddm/themes/`
- Ensures `/etc/sddm.conf` exists; sets `[Theme] Current=HyprFlux-sddm-theme` (inserts if missing)
- Non-fatal if theme folder missing

## 3.8 modules/08-gtk.sh (most defensive module)

1. Verifies theme dir exists (else falls back to `adwaita` with warning)
2. Installs GTK2 engines: `gtk-engines gtk-engine-murrine`
3. Writes **settings.ini** for both `gtk-3.0` and `gtk-4.0` (theme, icon, cursor, font, dark)
4. **Symlinks GTK4 CSS** (`gtk-4.0/gtk.css`, `gtk-dark.css`, `assets/`) because GTK4 ignores settings.ini
5. gsettings best-effort (only if schema present) — theme/icon/cursor/font + `color-scheme prefer-dark`
6. `nwg-look -x` export if available
7. Non-fatal on every step

## 3.9 modules/09-grub.sh

- Detects GRUB (`grub-install`/`grub-mkconfig`); skips silently if absent
- Extracts `HyprFlux-1080p.tar.xz` → `/tmp/hyprflux-grub`, finds inner `install.sh`, runs it with `sudo` (output silenced)

## 3.10 modules/10-plymouth.sh

- **Bugfix:** plymouth failure no longer kills the install (cosmetic boot screen)
- Installs `plymouth` if missing; extracts `hyprflux-plymouth.tar.xz` (strip-components=1) → `/usr/share/plymouth/themes/hyprflux`
- Adds `plymouth` hook to `/etc/mkinitcpio.conf` (`HOOKS=(plymouth ...`)
- `plymouth-set-default-theme -R hyprflux`
- Ensures `quiet splash` in `/etc/default/grub` + `grub-mkconfig`
- `mkinitcpio -P` rebuild (non-fatal)

## 3.11 modules/11-tmux.sh

- Clones `tmuxifier` fresh (removes existing), copies repo's `.tmuxifier/layouts/.` into it
- Clones TPM (`tmux-plugins/tpm`), runs `tpm/bin/install_plugins`

## 3.12 modules/12-zsh.sh

- Single purpose: remove leading `\n` from `print -P` line in `~/.oh-my-zsh/themes/refined.zsh-theme`
- Guarded; non-fatal if file missing

## 3.13 modules/13-wallpapers.sh

- Removes `~/Pictures/wallpapers`, then `clone_with_retry wallpapers-bank 5 --depth=1`
- Non-fatal after 5 attempts

## 3.14 modules/14-webapps.sh

- Reads `config/webapps.conf` lines: `Name|URL|IconName`
- `_download_icon()`: tries Homarr CDN (`cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/<name>[-light|-dark].png`), then Google S2 favicon API, then direct `favicon.ico`; validates with `file --mime-type`
- `_make_desktop_entry()`: writes `~/.local/share/applications/<icon>.desktop` with `Exec=chromium --new-window --ozone-platform=wayland --app=<url>`
- Default webapps: Netflix, WhatsApp, ChatGPT, YouTube, GitHub

## 3.15 modules/15-bibata.sh

- Extracts bundled `Bibata-Modern-Classic.tar.xz` → `~/.icons/Bibata-Modern-Classic`
- **Defensive normalization:** if `.hlc` files extracted flat, moves them under `hyprcursors/`; validates `manifest.hl` + `hyprcursors/` exist
- Updates `~/.config/hypr/UserConfigs/ENVariables.conf`: `env = HYPRCURSOR_THEME,Bibata-Modern-Classic` + `HYPRCURSOR_SIZE,24` (creates file if missing)
- NOTE: in the Lua migration this file became `UserConfigs/env-variables.lua` — the module still writes the legacy conf path (kept for compatibility; the live Lua config sets the same values via `hl.env`)

## 3.16 modules/16-ai-tools.sh

- `install_yay 5 claude-code opencode-bin openai-codex-bin` (configurable via `AI_TOOLS_AUR_PACKAGES`)

## 3.17 modules/17-optional-packages.sh (interactive)

- `install_optional_pacman`: foot, alacritty, lsd, bat, tmux, neovim, tldr, obs-studio, vlc, yazi, luacheck, luarocks, hyprpicker, obsidian, github-cli, noto-fonts-emoji, ttf-noto-nerd, noto-fonts
- `install_optional_yay`: visual-studio-code-bin, 64gram-desktop-bin, vesktop, foliate, localsend-bin, tuxedo-bin
- Both ask `ask_yes_no` before installing

## 3.18 modules/18-monitors.sh (hardware-aware)

**Detection chain** (first success wins):
1. `hyprctl -j monitors` (parsed via python3 → `NAME W H RR OX OY SCALE`)
2. `wlr-randr` (Wayland, no compositor needed; awk parses `"1920x1080" @ 60.00 Hz`)
3. `xrandr` (XWayland fallback)
4. Sentinel `FALLBACK 1920 1080 60 0 0 1.0` → wildcard monitor

**Outputs written:**
- `~/.config/hypr/monitors.conf` — legacy hyprlang format (`monitor=NAME,WxH@RR,OXxOY,SCALE`) + commented examples (mirror, bitdepth 10, QEMU Virtual-1)
- `~/.config/hypr/monitors.lua` — Lua format (`hl.monitor({...})`) with same comments; **this is the file nwg-displays ≥ 2.4 also writes**, so it's the live one for Hyprland ≥ 0.55
- `~/.config/hypr/Monitor_Profiles/default.conf` + `default.lua` — saved as restorable profile
## 3.19 modules/19-hardware-detect.sh (machine-specific setup)

Runs after 18; handles everything that varies machine-to-machine:

1. **GPU detection** (`lspci` VGA/3D/Display) → rewrites the GPU block in `UserConfigs/env-variables.lua` between `-- >>> GPU_CONFIG_START >>>` / `-- >>> GPU_CONFIG_END <<<` markers (idempotent):
   - `nvidia` → LIBVA_DRIVER_NAME=nvidia, __GLX_VENDOR_LIBRARY_NAME=nvidia, NVD_BACKEND=direct, GSK_RENDERER=ngl, GBM_BACKEND=nvidia-drm
   - `amd` → radeonsi + Mesa EGL vendor (50_mesa.json)
   - `intel` → iHD + Mesa EGL
   - `hybrid-amd-nvidia` / `hybrid-intel-nvidia` / `hybrid-amd-intel` → `AQ_DRM_DEVICES` built from real `/sys/class/drm/card*/device/vendor` order (preferred vendor first) + Mesa EGL
   - `none` (VM) → empty block, defaults apply
2. **Native monitor resolution** (same hyprctl → wlr-randr → xrandr → 1080p chain, self-contained if 18 skipped) → writes `monitors.lua` + `monitors.conf` + `Monitor_Profiles/default.*`
3. **Keyboard layout** (`localectl` → `setxkbmap` → `us`) → writes `kb_layout` in `UserConfigs/user-settings.lua`


**Lib helper detail:** `lib/packages.sh` — `install_pacman N pkgs...` runs `script -qfc "sudo pacman -Sy --noconfirm --needed ..."` in a loop, then re-verifies each package with `pacman -Qi` and retries only the missing ones. `install_yay` mirrors this with yay. Optional variants ask first.

---

# PART 4 — MAIN REPO: DESKTOP ENVIRONMENT (`.config/`)

## 4.1 `.config/` inventory

```
cava            # audio visualizer config
fastfetch       # fetch info config
foot            # foot terminal (foot.ini + colors.ini)
ghostty         # ghostty terminal config
hypr            # THE main config (detailed below)
kitty           # kitty terminal (kitty.conf + kitty-colors.conf)
Kvantum         # Kvantum theme engine config
mimeapps.list   # default apps
qt5ct, qt6ct   # Qt theming
rofi            # launcher themes
swaync          # notification center
waybar          # bar
wlogout         # logout screen
yazi            # terminal file manager
```

## 4.2 `.config/hypr/` inventory

```
hyprland.lua          # Lua entrypoint (replaces hyprland.conf)
hyprflux-colors.lua   # GENERATED Lua palette
hyprflux-colors/      # SOURCE palette: hyprflux-colors.conf (single source)
configs/keybinds.lua  # default keybinds
UserConfigs/          # user-tunable modules (12 files + 00-Readme)
scripts/              # 36 runtime scripts
UserScripts/          # 16 user-facing scripts
animations/           # animation presets
hyprlock/             # lock screen images (profile.jpg, relaxed_mario.png)
hyprlock.conf, hyprlock-1080p.conf
hypridle.conf         # idle daemon
application-style.conf
Monitor_Profiles/     # default.lua + README
monitors.lua          # GENERATED by nwg-displays/installer
workspaces.lua        # GENERATED by nwg-displays
wallpaper_effects/    # imagemagick effect cache
initial-boot.sh       # live-machine one-shot first boot
v2.4.0/               # nwg-displays version marker
```

### 4.2.1 `hyprland.lua` — the entrypoint (require order matters)

```lua
local Home = os.getenv("HOME")

local defaults = require("UserConfigs.user-defaults")
local colors = require("hyprflux-colors")

-- env MUST be loaded before any other hl.* use
require("UserConfigs.env-variables")
require("UserConfigs.user-settings")
require("UserConfigs.user-decorations")
require("UserConfigs.user-animations")

require("configs.keybinds")
require("UserConfigs.user-keybinds")
require("UserConfigs.laptops")

require("UserConfigs.window-rules")
require("UserConfigs.workspace-rules")   -- guide only

hl.on("hyprland.start", function()
    hl.exec_cmd(Home .. "/.config/hypr/initial-boot.sh")
end)
require("UserConfigs.startup-apps")
require("monitors")            -- nwg-displays generated
require("workspaces")          -- nwg-displays generated
require("UserConfigs.LaptopDisplay")
```

### 4.2.2 `UserConfigs/env-variables.lua` (full list)

| Group | Variables |
|-------|-----------|
| Toolkit backends | `GDK_BACKEND=wayland,x11,*`, `QT_QPA_PLATFORM=wayland;xcb`, `CLUTTER_BACKEND=wayland` |
| XDG | `XDG_CURRENT_DESKTOP=Hyprland`, `XDG_SESSION_DESKTOP=Hyprland`, `XDG_SESSION_TYPE=wayland` |
| Qt | `QT_AUTO_SCREEN_SCALE_FACTOR=1`, `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`, `QT_QPA_PLATFORMTHEME=qt5ct`/`qt6ct`, `QT_QUICK_CONTROLS_STYLE=org.hyprland.style` |
| XWayland scaling | `GDK_SCALE=1`, `QT_SCALE_FACTOR=1` |
| Cursors | `HYPRCURSOR_THEME=Bibata-Modern-Classic`, `HYPRCURSOR_SIZE=24`, `XCURSOR_THEME=…`, `XCURSOR_SIZE=24` |
| Apps | `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT=auto` |
| NVIDIA (live machine) | `AQ_DRM_DEVICES=/dev/dri/card2:/dev/dri/card1` (AMD primary), `__GLX_VENDOR_LIBRARY_NAME=mesa`, `__EGL_VENDOR_LIBRARY_FILENAMES=…/50_mesa.json`, `LIBVA_DRIVER_NAME=radeonsi` — documented with warnings about the 2026-08-04 login crash loop |
| Commented | full NVIDIA block, VM/software rendering, Aquamarine debug, Hyprland trace |

### 4.2.3 `UserConfigs/user-settings.lua` (flat config keys)

- **dwindle:** `preserve_split=true`, `special_scale_factor=1`
- **master:** `new_status=master`, `new_on_top=1`, `mfact=0.5`
- **general:** `resize_on_border=true`, `layout=dwindle`
- **input:** kb `us`, `ctrl:nocaps` (live), repeat 50/300, numlock default on, follow_mouse 1, touchpad (tap_to_click, natural_scroll), tablet transform 0
- **gestures:** workspace_swipe 500/invert/min_speed 30/cancel 0.5/create_new/forever (gesture *actions* moved to `hl.gesture` in 0.55)
- **misc:** no logo, no splash, `vrr=2`, dpms on mouse move, swallow off, ANR dialog on (threshold 15), focus_on_activate off
- **binds:** workspace_back_and_forth, allow_workspace_cycles, pass_mouse_when_bound off
- **xwayland:** enabled, force_zero_scaling
- **render:** direct_scanout=2
- **cursor:** sync_gsettings_theme, no_hardware_cursors=2, enable_hyprcursor, warp_on_change_workspace=2, no_warps
- **debug:** vfr=true

### 4.2.4 `UserConfigs/user-decorations.lua`

- borders 2px, gaps 2/4, `col.active_border=color12`, `col.inactive_border=color10` (from palette)
- rounding 10, active_opacity 1.0, inactive 0.9, dim_inactive 0.1, dim_special 0.8
- shadows off, blur on (size 6, passes 2, ignore_opacity, popups)
- group borders color15, groupbar color0

### 4.2.5 `UserConfigs/user-animations.lua`

7 bezier curves (wind, winIn, winOut, liner, overshot, smoothOut, smoothIn) + 12 animations (windows*, border, borderangle, fade, workspaces*). **Note:** Lua API caps animation speed at 100 ds (hyprlang allowed 180). This file is copied by `Animations.sh` from `animations/` presets then applied via `hyprctl config full-reload`.

### 4.2.6 `configs/keybinds.lua` (default binds, full list)

**System/exit/lock/power:**
| Bind | Action |
|------|--------|
| CTRL+ALT+Delete | exit Hyprland |
| SUPER+Q | close window |
| SUPER+SHIFT+Q | kill active process |
| CTRL+ALT+L | lock screen |
| CTRL+ALT+P | wlogout power menu |
| SUPER+N | swaync toggle |
| SUPER+SHIFT+E | Quick Settings menu |

**Layout-aware helper (the `layoutMsgIf` pattern):**

```lua
local function layoutMsgIf(layout, msg)
    return function()
        if hl.get_active_workspace().tiled_layout == layout then
            hl.dispatch(hl.dsp.layout(msg))
        end
    end
end
```

Master-guarded: SUPER+CTRL+D removemaster, SUPER+I addmaster, SUPER+K cycleprev, SUPER+CTRL+RETURN swapwithmaster. Dwindle-guarded: SUPER+O togglesplit. Plus SUPER+SHIFT+I rotatesplit, SUPER+P pseudo toggle.

**Window ops:** SUPER+J cycle_next (any layout), resize SUPER+SHIFT+arrows (50px), move SUPER+CTRL+arrows, swap SUPER+ALT+arrows, focus SUPER+arrows.

**Workspaces:** SUPER+tab m+1/m-1, SUPER+U toggle special:nyx, SUPER+SHIFT+U move to special:nyx, number keys 1-10 via **keycodes** (code:10..code:19 — layout-independent) for focus/move/silent-move, brackets move ws ±1 (±silent), mouse scroll + period/comma cycle existing workspaces, mouse:272/273 drag move/resize.

**Media keys:** XF86AudioRaise/Lower (Volume.sh), MicMute, Mute, Sleep, Rfkill (AirplaneMode); `code:164` play/pause (KEY_PLAYPAUSE — Lua API rejects the XF86AudioPlayPause keysym), Next/Prev/Stop.

**Screenshots:** SUPER+Print now, +SHIFT area, +CTRL in5, +CTRL+SHIFT in10, ALT+Print active window, SUPER+SHIFT+S swappy.

### 4.2.7 `UserConfigs/user-keybinds.lua` (app binds)

| Bind | App/action |
|------|-----------|
| SUPER+D | rofi drun main menu |
| SUPER+RETURN | terminal (defaults.term = kitty live) |
| SUPER+F | file manager (thunar) |
| SUPER+K | Kdenlive |
| SUPER+B | Firefox |
| SUPER+R | Foliate ebook reader |
| SUPER+V | clipboard manager |
| SUPER+C | VS Code (`--ozone-platform=x11`) |
| SUPER+O | Obsidian |
| SUPER+S | Spotify PWA |
| SUPER+X | Vesktop |
| SUPER+T | Telegram (64gram) |
| SUPER+M | Free Download Manager |
| SUPER+E | Tmuxifier projects |
| SUPER+G | GitRepoClone |
| SUPER+SHIFT+H | KeyHints cheat sheet |
| SUPER+SHIFT+R | Refresh waybar/swaync/rofi |
| SUPER+SHIFT+O | toggle blur |
| SUPER+SHIFT+G | GameMode toggle |
| SUPER+SHIFT+T | toggle tuned daemon |
| SUPER+SHIFT+D | SyncDotfiles |
| SUPER+SHIFT+B | SyncBlog |
| SUPER+SHIFT+L | ChangeLayout cycle |
| SUPER+SHIFT+N | ObsidianGenerate |
| SUPER+SHIFT+P | hyprpicker autocopy |
| SUPER+SHIFT+F | fullscreen |
| SUPER+SHIFT+RETURN | dropdown terminal |
| SUPER+CTRL+F | fake fullscreen (maximized) |
| SUPER+SPACE | float toggle |
| SUPER+ALT+SPACE | All-Float Mode (Lua-native, replaces `workspaceopt allfloat`) |
| SUPER+ALT+E | rofi emoji |
| SUPER+ALT+mouse | cursor zoom (Lua-native via `hl.get_config`/`hl.config`) |
| SUPER+CTRL+ALT+B | waybar toggle (SIGUSR1) |
| SUPER+SHIFT+M | RofiBeats online music |
| SUPER+SHIFT+W ×2 | WallpaperSelect + WallpaperEffects (both fire) |
| CTRL+ALT+W | random wallpaper |
| SUPER+CTRL+O | toggle window opacity |
| SUPER+SHIFT+K | keybinds search |
| SUPER+SHIFT+A | animations menu |
| SUPER+CTRL+C | calculator |

### 4.2.8 `UserConfigs/laptops.lua`

ASUS-laptop-specific (ASUS ROG):
- Device rule: `asue1209:00-04f3:319f-touchpad` enabled
- XF86KbdBrightness +/- (BrightnessKbd.sh), XF86Launch1 = rog-control-center (Armory Crate), XF86Launch3 = `asusctl led-mode -n`, XF86Launch4 = `asusctl profile -n` (fan profiles)
- XF86MonBrightness +/- (Brightness.sh), XF86TouchpadToggle
- F6 screenshot variants (no PrintSrc key)
- Lid-switch binds commented with caveats (LaptopDisplay.lua mechanism)

### 4.2.9 `UserConfigs/window-rules.lua` (97 rules + 2 layer rules, grouped)

| Group | Rules |
|-------|-------|
| browser tags | chromium/firefox tagged `+browser` (6 rules) |
| notif tags | notification windows |
| HyprFlux settings tag | rofi/swaync/wlogout overrides |
| terminal tags | kitty/foot/ghostty tagged |
| email tags | 2 |
| project tags | 3 |
| screenshare tag | 1 |
| IM tags | discord/vesktop/telegram/64gram/slack (6) |
| game tags | steam/lutris/heroic |
| gamestore tags | 3 |
| file-manager tags | thunar/nemo/nautilus |
| wallpaper tag | 1 |
| multimedia tags | 2 |
| multimedia-video | mpv/vlc |
| settings tags | 12 (blueman, pavucontrol, printers, nmtui, etc.) |
| custom rules | 3 |
| viewer tags | 3 |
| special override | 1 |
| position rules | 6 (center on open: nwg-displays, qalculate, etc.) |
| idle inhibit | 1 |
| workspace rules | 9 (VSCode→1, chrome-for-testing→6, browsers→2, files→3, IM→4, games→6, VMs→9, obsidian→10) |
| silent workspace | 3 |
| float rules | 18 (calculators, download managers, auth dialogs, steam popups, fdm, proton-auth, windscribe) |
| float popups/dialogs | 7 (auth, codium, heroic, steam, add-folder, save-as, open-files, SDDM background yad) |
| opacity rules | 4 (terminal tag 0.8/0.7, gedit, deluge, seahorse) |

Layer rules: rofi (blur, ignore_alpha 0), notifications (blur, ignore_alpha 0).

Live-only rule 97: `chromium-browser` + title `Chrome for Testing` → workspace 6 silent (Playwright MCP browser, title-matched to avoid real Chromium).

### 4.2.10 `UserConfigs/startup-apps.lua`

On `hyprland.start`:
1. `awww-daemon --format xrgb` (wallpaper daemon; mpvpaper video wallpaper commented)
2. `dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP`
3. `systemctl --user import-environment ...`
4. `Polkit.sh`
5. `nm-applet --indicator`
6. `swaync`
7. `waybar`
8. `wl-paste --type text --watch cliphist store` + image variant (clipboard history capture)
9. `hypridle`
10. `systemctl --user restart hypr-refresh-rate.service` (live machine)

Commented: RainbowBorders, WallpaperAutoChange, blueman-applet, rog-control-center, PortalHyprland, persistent awww wallpaper.

### 4.2.11 `hypridle.conf`

- `lock_cmd = pidof hyprlock || hyprlock`, `before_sleep_cmd = loginctl lock-session`, `after_sleep_cmd = hl.dsp.dpms on`
- Listener 1: 540s warn notify "You are idle!" / "Oh! you're Back"
- Listener 2: 600s `loginctl lock-session`
- Commented: 30s dpms-off-when-locked, 630s dpms off, 1200s suspend

### 4.2.12 `hyprlock.conf` (+ 1080p variant)

- Sources the colors .conf directly (`source = ~/.config/hypr/hyprflux-colors/hyprflux-colors.conf` — hyprlock still reads hyprlang)
- Background: `hyprlock/relaxed_mario.png`, blur 3 passes, contrast/brightness/vibrancy tweaks
- Profile image: `hyprlock/profile.jpg`, border `$lock_border`, size 160, rounded, centered
- Date/time labels with `cmd[update:1000]` (LC_TIME=en_US), user label, song label, input field with `$lock_*` colors, capslock indicator (1080p variant has placeholder bg + capslock color)

### 4.2.13 `monitors.lua` / `workspaces.lua` (generated)

- `monitors.lua`: `hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1.0 })` + fallback wildcard (live machine values)
- `workspaces.lua`: workspace rules for monitor binding (nwg-displays managed)

---

## 4.3 Waybar

### Structure (real files, not symlinks — changed from old symlink approach)

```
.config/waybar/
├── config                  # top-level bar config (55 lines) — includes 6 module files
├── style.css               # @import url("style/HyprFlux-Default.css")
├── hyprflux-colors.css     # GENERATED @define-color palette
├── Modules                 # 10.4KB: all standard module definitions
├── ModulesWorkspaces       # 7.2KB: workspace styles (circles, roman, chips...)
├── ModulesCustom           # 6.9KB: custom/ modules (menu, power, lock, weather...)
├── ModulesGroups           # 2.5KB: group/ modules (app_drawer, notify, audio, status...)
├── ModulesVertical         # 3.2KB: vertical variants
├── UserModules             # 214B: user extension point
├── configs/HyprFlux-Default-Laptop   # full config copy source
└── style/HyprFlux-Default.css        # 307 lines, full theme
```

### `config` bar layout

```json
"modules-left":    [cava_mviz, playerctl, hyprland/window]
"modules-center":  [workspaces#rw, clock, weather, idle_inhibitor]
"modules-right":   [app_drawer, notify, tray, tty, updater, laptop, mobo_drawer,
                    audio, status]
```

### Modules inventory (Modules file)

- **temperature** — hwmon paths, critical 82, `{icon} {temperatureC}°C`, right-click nvtop
- **backlight** — icon-only, scroll = Brightness.sh, `backlight#2` intel variant
- **battery** — states good 95/warning 30/critical 15, charge cap; formats for charging/plugged/full; middle-click ChangeBlur, right-click Wlogout
- **bluetooth** — click blueman-manager
- **clock** — AM/PM primary, alt full date, calendar tooltip; `clock#2` 24h, `clock#3` date+time, `clock#4` full date, `clock#5` compact
- **cpu** — `{usage}% 󰍛`, alt bars, right-click system-monitor
- **disk** — `{percentage_used}%` of `/`
- **hyprland/language**, **hyprland/submap**, **hyprland/window** (rewrite rules for firefox/zsh/kitty titles, 25 max length, offscreen "(inactive)")
- **idle_inhibitor** — / icons
- **keyboard-state** — capslock 󰪛 locked/unlocked
- **memory** — `{used:0.1f}G`, right-click btop
- **mpris** — playerctl control with player/status icon maps, click prev, middle pause, right next
- **network** — wifi/ethernet icons, tooltip with IP + bandwidth; `network#speed` bandwidth variant
- **power-profiles-daemon** — icon per profile
- **pulseaudio** — volume, bluetooth variant, muted, icons per device type; scroll Volume.sh; `pulseaudio#1` pamixer variant; `pulseaudio#microphone` with source formats
- **tray** — 20px icons
- **wireplumber** — wireplumber volume variant
- **wlr/taskbar** — taskbar with ignore-list (rofi, kitty, kitty-dropterm)

### ModulesCustom inventory

arrows 1-10 (separators), browser, cava_mviz (audio visualizer), cycle_wall, dot_update, file_manager, hint, hypridle, hyprpicker, keyboard, light_dark (removed from repo but module exists), lock, menu, playerctl, power, quit, reboot, separators (blank/blank_2/blank_3/dot/line), settings, swaync, tty, updater, weather.

### ModulesGroups

app_drawer, audio, connections, laptop, mobo_drawer, motherboard, notify, power, power#vert, status — group dropdowns with drawer popups.

### Style (HyprFlux-Default.css, 307 lines)

Uses `@define-color` from hyprflux-colors.css; rounded pill modules, separators, tooltips, group popup styling, cava bars, workspace active/persistent colors, laptop group specifics.

---

## 4.4 Rofi

```
config.rasi            → @import master-config.rasi; font JetBrains Mono 10/9
master-config.rasi     → full theme (234 lines) + @theme hyprflux-colors.rasi
hyprflux-colors.rasi   → GENERATED palette (rofi_* vars + color0-15)
```

Sub-configs (each for a script):
- `config-Animations.rasi` — Animations.sh menu (spacing 6)
- `config-calc.rasi` — RofiCalc.sh (qalculate entry)
- `config-clipboard.rasi` — ClipManager.sh
- `config-compact.rasi` — compact layout, imported by Beats configs
- `config-edit.rasi` — Quick Settings menu (size 0% → dmenu-like)
- `config-emoji.rasi` — RofiEmoji.sh
- `config-keybinds.rasi` — KeyBinds.sh
- `config-Monitors.rasi` — MonitorProfiles.sh
- `config-rofi-Beats.rasi` / `-menu.rasi` — RofiBeats.sh music menus
- `config-wallpaper.rasi` — WallpaperSelect.sh (6-column grid)
- `config-wallpaper-effect.rasi` — WallpaperEffects.sh

**master-config.rasi key values:** window 44% width, radius 14, centered; mainbox padding 5; inputbar margin 10; entry font JetBrainsMono Nerd Font 10, placeholder "  Search "; listview 8 lines, spacing 8; element padding 5, radius 5, spacing 10, icons 20px; mode-switcher with button width 4%; scrollbar 4px handle 8px; message/textbox/error styling.

---

## 4.5 SwayNC

**config.json:** right-top overlay, control-center-width 360, height 1296 (90% of 1440p), margin-top 5/right 8, icon-size 34, body-image 300×300, timeout 6s (low/critical 3s), transition 200ms, widgets: dnd, buttons-grid, mpris, title, notifications. Buttons-grid actions: Wlogout, LockScreen, `hyprctl dispatch exit`, AirplaneMode, mute toggle. DND text "Do Not Disturb", title " Notifications" with Clear button ().

**style.css:** 349 lines. Colors block injected by sync-colors.sh (color12 #7D4AB4, noti-bg #0e0e16, noti-fg #cdd6f4, close #f7768e, accent #89dceb, dnd #d20f39, progress #00ffff). Font JetBrains Mono Nerd. Full styling for: notification-row hover, notification cards, groups, image, close-button (red bg), action buttons, inline-reply, body-image, summary/time/body typography, control-center (rounded 16, purple-tinted border), floating-notifications, widget-title/dnd/switch (GTK4 hierarchy), mpris, buttons-grid, scrollbar (hidden via GTK4 `scrollbar > range > trough > slider` transparent/zero-size).

---

## 4.6 Wlogout

**layout:** 6 buttons — Lock (l), Reboot (r), Shutdown (s), Logout (e), Suspend (u), Hibernate (h) — actions wired to LockScreen.sh / systemctl / loginctl.
**style.css:** 87 lines, colors from palette (logout_bg rgba(1E1E2E99), hover 91D7E3), centered grid.

---

## 4.7 Terminals

**kitty.conf** (1090 lines): JetBrainsMono Nerd Font 14, adjust_line_height 100%, full keybindings, tabs/splits, hints, includes `kitty-colors.conf` (generated 16-color palette + foreground/background/cursor).

**foot.ini:** JetBrainsMono Nerd 9, pad 12x12 center, scrollback 5000, beam cursor, url-mode, alpha 0.80, includes `colors.ini` (generated).

**ghostty:** present in .config (user extension).

---

## 4.8 Runtime Scripts (`.config/hypr/scripts/`, 36 files)

| Script | Purpose |
|--------|---------|
| AirplaneMode.sh | rfkill-based wifi toggle |
| Animations.sh | pick animation preset from rofi, copy over user-animations.lua, reload |
| Battery.sh | battery indicator helper |
| Brightness.sh / BrightnessKbd.sh | brightnessctl screen/kbd (MAX 95%, MIN 5 — user-set) |
| ChangeBlur.sh | toggle blur settings live via `hyprctl eval` |
| ChangeLayout.sh | **pure layout cycle** Dwindle→Master→Scrolling (no unbind/rebind — fixed Kdenlive clobber) |
| ClipManager.sh | cliphist + rofi + wl-copy clipboard manager |
| Distro_update.sh | system update (check + apply) |
| Dropterminal.sh | dropdown terminal toggle |
| GameMode.sh | **state-based toggle** (state file in $XDG_RUNTIME_DIR): disables animations/blur/shadows/rounding/gaps; restores exact previous values on disable |
| HyprFlux_Quick_Settings.sh | YAD/rofi quick settings menu (monitors, profiles, blur, layout, gamemode, updates…) |
| HyprFluxUpdate.sh | checks repo for updates (git fetch + compare) |
| Hypridle.sh | custom idle_inhibitor for waybar |
| KeyBinds.sh | rofi search over parsed keybinds (config-keybinds.rasi) |
| KeyHints.sh | curated ~101-entry cheat sheet |
| KillActiveProcess.sh | kill active window process |
| LockScreen.sh | hyprlock launcher |
| MediaCtrl.sh | playerctl wrapper (play/pause/next/prev/stop) |
| MonitorProfiles.sh | apply saved monitor profiles via rofi |
| Polkit.sh | first available polkit agent (lxsession-gtk/kde/gnome…) |
| PortalHyprland.sh | manual xdg-desktop-portal-hyprland start |
| Refresh.sh / RefreshNoWaybar.sh | restart waybar (config+style), swaync, rofi, wallpapers |
| RofiEmoji.sh | emoji picker (self-extracting emoji data; `bash -n` false-positive) |
| ScreenShot.sh | grim/slurp/swappy screenshots (now/area/in5/in10/active/swappy) |
| Sounds.sh | system sounds via canberra |
| SwitchKeyboardLayout.sh | kb_layouts cycle (reads user-settings) |
| Tak0-Per-Window-Switch.sh | per-window keyboard layout |
| TouchPad.sh | touchpad toggle via `hyprctl eval` hl.device |
| Volume.sh | pamixer volume/mic (inc/dec/toggle/toggle-mic/mic-inc/mic-dec) |
| WallpaperAwww.sh | sync awww wallpaper to rofi preview + effects cache |
| WaybarCava.sh | cava FIFO pipe setup for waybar |
| WaybarScripts.sh | shared defaults + handlers for waybar module clicks (nmtui, btop, nvtop…) |
| Wlogout.sh | wlogout launcher |

## 4.9 UserScripts (`.config/hypr/UserScripts/`, 16 files)

| Script | Purpose |
|--------|---------|
| GitRepoClone.sh | SUPER+G: rofi GitHub repo clone with start/success/failure(+reason) notifications |
| ObsidianGenerate.sh | Obsidian note generator |
| RofiBeats.sh | online music (beets/radio) via rofi menus |
| RofiCalc.sh | qalculate-gtk calculator via rofi |
| SyncBlog.sh | blog sync |
| SyncDotfiles.sh | dotfiles sync |
| TmuxifierProjects.sh | tmuxifier project picker |
| Toggle-tuned.sh | toggle tuned daemon |
| WallpaperAutoChange.sh | periodic wallpaper auto-change (awww) |
| WallpaperEffects.sh | imagemagick wallpaper effects (shaders → cache) |
| WallpaperRandom.sh | random wallpaper |
| WallpaperSelect.sh | wallpaper picker (rofi grid, mpvpaper video support) |
| Weather.py / Weather.sh | wttr.in weather (stdlib-only rewrite, JSON + hyprlock cache) |
| notes-ai/ | AI notes helper |
| __pycache__/ | python cache (Weather.py) |

---

# PART 5 — COLOR SYSTEM (single source of truth)

## 5.1 Source file: `hyprflux-colors/hyprflux-colors.conf` (143 lines, 6 sections)

| Section | Variables |
|---------|-----------|
| CORE UI | background #010102, foreground #FDF8FE, color0-15 (purple-led: color12 #7D4AB4), cursor |
| LOCK SCREEN | lock_font, lock_outer, lock_text, lock_text_dim, lock_border, lock_box, lock_box_border, lock_text_faint, lock_1080_bg, lock_caps |
| TERMINAL ANSI | term_foreground #fffbf6, term_background #0a0e14, term_cursor, term_color0-15 (shared kitty+foot) |
| NAVBAR | bar_base #1e1e2e (catppuccin mocha), mantle, crust, text, subtext0/1, surface0-2, overlay0-2, 15 accent colors (blue→rosewater), bar_bg_alt, bar_main_bg |
| NOTIFICATIONS | notif_bg #0e0e16, notif_fg #cdd6f4, notif_fg_dim, notif_close_bg #f7768e, notif_accent #89dceb, notif_dnd_text #d20f39, notif_progress #00ffff, notif_text_sel |
| LOGOUT | logout_bg rgba(1E1E2E99), logout_btn_bg, logout_hover_bg #91D7E3, logout_hover_text |
| ROFI | rofi_active #8378CD, foreground, background #101012, urgent, alt_active, sel_active/normal/urgent, border, selected, text_sel, text, text_2, bg_2, color0-15 |

## 5.2 Generator: `utilities/sync-colors.sh`

- Parses `$name = rgb(...)` / `rgba(...)` lines (strips comments, trims)
- Generates 6 files + 2 injections:
  1. `hyprflux-colors.lua` (Hyprland `local colors = {...}`)
  2. `rofi/hyprflux-colors.rasi` (rasi `* { var: #hex; }`)
  3. `waybar/hyprflux-colors.css` (`@define-color`) — also used by **swaync + wlogout via injected blocks** (GTK4 CSS cannot `@import`; sync-colors injects the `@define-color` block directly into their style.css files)
  4. `kitty/kitty-colors.conf`
  5. `foot/colors.ini`
- `rgba_dec()` helper converts `rgba(RRGGBBAA)` → decimal `r,g,b,a` for CSS alpha values
- CI gates that generated files are up to date

---

# PART 6 — ARCH-HYPRLAND (the base installer)

## 6.1 Repo structure

```
base-installer/
├── install.sh           # whiptail-based interactive installer (~515 lines)
├── auto-install.sh      # clone+run helper
├── uninstall.sh
├── install-scripts/     # 24 component scripts + Global_functions.sh
├── assets/              # GTK/Thunar config copies
└── CHANGELOGS.md, README.md, LICENSE.md, CONTRIBUTING.md, COMMIT_MESSAGE_GUIDELINES.md
```

## 6.2 install.sh flow

1. Colors, log dir `Install-Logs/`, refuse root (must run as user)
2. PulseAudio conflict check (refuses if pulseaudio installed)
3. Ensure `base-devel` + `libnewt` (whiptail)
4. ASCII "base-installer" banner
5. `whiptail` welcome msgbox + proceed yes/no
6. AUR helper selection checklist (yay/paru)
7. Login-manager detection (non-SDDM warning), NVIDIA detection msgbox
8. **Option checklist** (whiptail): sddm, nvidia, nouveau, input_group, quickshell, xdph, thunar, etc.
9. Confirm summary
10. Execution order:
    - `00-base.sh` (base-devel, archlinux-keyring, findutils)
    - `pacman.sh` (pacman.conf spices: Color/CheckSpace/VerbosePkgLists/ParallelDownloads/ILoveCandy + `pacman -Sy`)
    - **HyprFlux custom scripts injected:**
      - `cp "$HYPRFLUX_DIR/scripts/zsh.sh" ~/base-installer/install-scripts/zsh.sh` (replaces the base zsh script)
      - (merged layout: base-dots is already pre-patched — no replace_reads needed)
      - `bash "$HYPRFLUX_DIR/scripts/initial.sh"` (Chaotic-AUR keys + repo + yay)
    - `yay.sh` / `paru.sh` (AUR helper)
    - `01-hypr-pkgs.sh` (Hyprland ecosystem packages — full list below)
    - `pipewire.sh`, `fonts.sh`, `hyprland.sh`
    - Per selected option: `sddm.sh`, `nvidia.sh`, `nvidia_nouveau.sh`, `InputGroup.sh`, `quickshell.sh`, `xdph.sh`, `thunar.sh`, `sddm_theme.sh`, `gtk_themes.sh` (commented), `dotfiles-main.sh`, `02-Final-Check.sh`

## 6.3 The install-scripts (detail)

| Script | Packages / actions |
|--------|--------------------|
| `00-base.sh` | base-devel, archlinux-keyring, findutils |
| `pacman.sh` | pacman.conf Color/CheckSpace/VerbosePkgLists/ParallelDownloads + ILoveCandy, `pacman -Sy` |
| `yay.sh` | clones `yay-bin` from AUR, `makepkg -si`, then `$ISAUR -Syu` |
| `paru.sh` | same pattern for paru |
| `01-hypr-pkgs.sh` | **hypr_package:** bc, cliphist, curl, grim, gvfs, gvfs-mtp, hyprpolkitagent, imagemagick, inxi, jq, kitty, kvantum, libspng, nano, network-manager-applet, pamixer, pavucontrol, playerctl, python-requests, python-pyquery, qt5ct, qt6ct, qt6-svg, rofi, slurp, swappy, swaync, swww, unzip, waybar, wget, wl-clipboard, wlogout, xdg-user-dirs, xdg-utils, yad. **hypr_package_2:** brightnessctl, btop, cava, loupe, fastfetch, gnome-system-monitor, mousepad, mpv, mpv-mpris, nvtop, nwg-look, nwg-displays, pacman-contrib, qalculate-gtk, yt-dlp. **uninstall:** aylurs-gtk-shell, dunst, cachyos-hyprland-settings, mako, rofi, rofi-lbonn-wayland, rofi-lbonn-wayland-git |
| `hyprland.sh` | hyprland + hypridle + hyprlock (skips if present) |
| `pipewire.sh` | pipewire, wireplumber, pipewire-audio/alsa/pulse, sof-firmware; disables pulseaudio; enables user services |
| `fonts.sh` | adobe-source-code-pro, noto-fonts-emoji, otf-font-awesome, ttf-droid, fira-code, fantasque-nerd, jetbrains-mono(+nerd), victor-mono, noto-fonts |
| `bluetooth.sh` | bluez, bluez-utils, blueman + enable bluetooth.service |
| `sddm.sh` | qt6-declarative/svg/virtualkeyboard/multimedia-ffmpeg, qt5-quickcontrols2, sddm; disables lightdm/gdm/lxdm; enables sddm; creates wayland-sessions dir |
| `sddm_theme.sh` | *(removed — HyprFlux ships its own SDDM theme via module 07)* |
| `nvidia.sh` | nvidia-dkms/settings/utils, libva, libva-nvidia-driver, per-kernel headers; removes hyprland-git/nvidia variants; mkinitcpio modules + rebuild |
| `nvidia_nouveau.sh` | nouveau blacklist |
| `InputGroup.sh` | adds user to input group |
| `quickshell.sh` | quickshell + ags (QML shell) |
| `zsh.sh` | (replaced by HyprFlux's) zsh, oh-my-zsh, plugins, chsh |
| `zsh_pokemon.sh` | pokemon-colorscripts prompt theme |
| `thunar.sh` | thunar + volman + tumbler + ffmpegthumbnailer + archive-plugin + xarchiver; copies assets gtk-3.0/Thunar/xfce4 configs |
| `thunar_default.sh` | thunar as default file manager (mimeapps) |
| `xdph.sh` | xdg-desktop-portal-hyprland + gtk + umockdev |
| `gtk_themes.sh` | gtk themes |
| `dotfiles-main.sh` | verifies merged base-dots checkout — config deployed once by dotsSetup module 02 (single source; copy.sh NOT run — would be a redundant second copy) |
| `02-Final-Check.sh` | post-install verification |
| `rog.sh`, `disk-monitor.sh`, `temp-monitor.sh`, `battery-monitor.sh` | ROG laptop extras + monitor scripts |
| `ags.launcher.com.github.Aylur.ags` | ags desktop file |

## 6.4 Global_functions.sh

- `install_package`, `install_package_pacman`, `uninstall_package` — with `ISAUR=$(command -v yay || command -v paru)` detection, `stdbuf -oL` logging
- The chroot wrapper patches the ISAUR line to add a `/usr/bin/yay` fallback (chroot PATH issues)

---

# PART 7 — HYPRFLUX-ISO (the live ISO)

## 7.1 Repo structure (annotated)

```text
HyprFlux-ISO/
├── build.sh                          # mkarchiso wrapper
├── profiledef.sh                     # archiso profile definition
├── packages.x86_64                   # live-env package list
├── pacman.conf                       # build-time pacman (multilib)
├── airootfs/                         # live filesystem overlay
│   ├── etc/
│   │   ├── hostname, locale.conf, locale.gen
│   │   ├── passwd (root shell zsh), shadow, motd
│   │   ├── mkinitcpio.conf.d/archiso.conf
│   │   ├── mkinitcpio.d/linux.preset
│   │   ├── plymouth/plymouthd.conf
│   │   └── systemd/
│   │       ├── journald.conf.d/volatile-storage.conf
│   │       ├── logind.conf.d/do-not-suspend.conf
│   │       ├── system/pacman-init.service
│   │       ├── system/etc-pacman.d-gnupg.mount
│   │       └── system/getty@tty1.service.d/autologin.conf
│   ├── root/
│   │   ├── .zlogin                    # auto-launch installer on tty1
│   │   ├── hyprflux-install.sh        # main TUI installer (1065 lines)
│   │   └── lib/
│   │       ├── tui.sh                 # TUI framework (654 lines)
│   │       ├── common.sh              # shared utilities (182 lines)
│   │       └── hyprflux-chroot-wrapper.sh  # chroot integration (544 lines)
│   └── usr/share/plymouth/themes/hyprflux/  # boot splash theme (progress PNGs + script)
├── efiboot/loader/                    # systemd-boot entries (UEFI)
├── grub/grub.cfg + themes/            # GRUB UEFI boot + HyprFlux theme
├── syslinux/                          # BIOS boot configs
├── plans/                             # 6 phase design docs
├── test-qemu.sh                       # QEMU test launcher
├── out/                               # built ISO artifacts
├── instructions.md                    # original requirements spec
├── AGENTS.md                          # project architecture contract
└── .github/workflows/build-iso.yml    # CI
```

## 7.2 profiledef.sh (boot modes)

```bash
iso_name="hyprflux"
iso_label="HYPRFLUX_$(date +%Y%m)"
install_dir="hyprflux"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.grub')   # GRUB = UEFI, Syslinux = BIOS
arch="x86_64"
airootfs_image_type="squashfs"            # xz compression, x86 BCJ, 1M blocks
file_permissions: /root, installer, lib scripts = 755; /etc/shadow = 400
```

## 7.3 packages.x86_64 (live env)

- **Base:** base, linux, linux-firmware, mkinitcpio(+archiso), syslinux
- **Install tools:** arch-install-scripts, gptfdisk, dosfstools, e2fsprogs, parted
- **Bootloader (target + ISO EFI):** grub, efibootmgr, plymouth, edk2-shell
- **Network (NetworkManager only):** networkmanager, iwd, iw, wpa_supplicant, dhcpcd, openssh, curl, wget
- **TUI:** gum, fzf
- **Utilities:** vim, nano, git, sudo, less, reflector, pciutils
- **Firmware:** amd-ucode, intel-ucode, sof-firmware
- **Shell:** zsh (root shell; .zlogin launches installer)
- **Filesystems:** btrfs-progs, xfsprogs, ntfs-3g

## 7.4 Live environment design

- root auto-login on tty1 via `getty@tty1.service.d/autologin.conf`:
  ```
  ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root - $TERM
  ```
- `.zlogin`: only on tty1 → `bash ~/hyprflux-install.sh || true` → on exit prints "Installer exited. You are now in a root shell." + re-run hint. Other TTYs = plain debug shell.
- systemd tweaks: pacman-init.service (keyring init), etc-pacman.d-gnupg.mount, journald volatile-storage, logind do-not-suspend
- Plymouth theme ships in airootfs (`hyprflux.script` + ~160 progress PNG frames + `hyprflux.plymouth`)
- **`install_dir="hyprflux"`** → all boot entries must use `archisobasedir=%INSTALL_DIR%`

## 7.5 Boot configs (full detail)

### GRUB (UEFI) — grub/grub.cfg

- Modules: part_gpt/msdos, fat, iso9660, ntfs(+comp), exfat, udf, all_video, gfxterm, gfxmenu, png
- HyprFlux theme loaded from `/boot/grub/themes/HyprFlux/theme.txt` (absolute ISO path)
- gfxmode 1920x1080 → 1280x720 → 1024x768 → auto
- Serial console support
- **Menu entries:**
  1. "HyprFlux Installer (x86_64, UEFI/BIOS)" — `archisobasedir=%INSTALL_DIR% archisosearchuuid=%ARCHISO_UUID% cow_spacesize=2G quiet splash loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0`
  2. "… - Copy to RAM" — same + `copytoram=y`
  3. UEFI Shell (if present), UEFI Firmware Settings, Shutdown, Restart
- timeout 15, menu colors white/black + highlight black/light-gray

### Syslinux (BIOS) — syslinux/

- `syslinux.cfg` → whichsys.c32 dispatch between pxe/sys/iso variants
- `archiso_head.cfg`, `archiso_sys.cfg` + `archiso_sys-linux.cfg` (standard archiso structure), `archiso_pxe*.cfg`, `archiso_tail.cfg`

### systemd-boot (efiboot/) — secondary UEFI entries

- `loader.conf`: timeout 15, default `01-hyprflux-*`, editor no, beep on
- `01-hyprflux-x86_64-linux.conf`: "HyprFlux Installer (%ARCH%, UEFI)" with `archisobasedir=%INSTALL_DIR% archisosearchuuid=%ARCHISO_UUID% cow_spacesize=2G`
- `02-hyprflux-x86_64-linux-ram.conf`: same + `copytoram=y`

## 7.6 The TUI installer — `hyprflux-install.sh` (1065 lines)

### Structure

- `set -euo pipefail`; sources `lib/tui.sh` + `lib/common.sh`
- Config vars: INSTALL_TIMEZONE/LOCALE/KEYMAP/HOSTNAME/USERNAME/PASSWORD/DISK/BOOT_MODE/HAS_NVIDIA, USE_SWAP/SWAP_SIZE, EFI_PART/BIOS_PART/SWAP_PART/ROOT_PART
- `check_terminal_size` + `show_banner` at start
- ERR trap: stop progress → `die()` → **drops to a debug shell** (subshell so EXIT traps still fire) → exit 1
- Pre-flight: `detect_boot_mode` (efivars dir) + `detect_nvidia` (lspci — **must run on live, not in chroot**, no PCI bus in chroot)

### Step 0 — Network setup

- `check_internet` (ping archlinux.org)
- If offline: start NetworkManager, menu: Ethernet (auto DHCP via nmcli), WiFi (scan → top-20 list by signal → password → connect), Manual (drop to bash shell), Skip
- Loops until online

### Step 1 — Welcome

- Requirements text (internet, disk to format, 20GB free) + `tui_yesno` continue

### Step 2 — Timezone

- Auto-detect via `https://ipapi.co/timezone` (5s timeout), validate against `/usr/share/zoneinfo/`
- Else: full zoneinfo list (excluding posix/right) via `tui_search` (gum filter); fallback UTC

### Step 3 — Locale

- Parses `/etc/locale.gen` (falls back to `/usr/share/i18n/SUPPORTED` if stub < 10 UTF-8 entries) — extracts first-column locale names via awk
- `tui_search` pick; fallback en_US.UTF-8

### Step 4 — Keyboard

- Common list (us, uk, de, fr, es, pt-latin1, it, br-abnt2, ru, jp106, kr, pl, se, nl, dvorak, colemak) + "[Show all layouts...]" via `localectl list-keymaps` search
- Applies `loadkeys` live

### Step 5 — Hostname

- `tui_input` (default hyprflux), trims gum-added spaces, validates `^[a-zA-Z][a-zA-Z0-9-]{0,62}$`

### Step 6 — User account

- Username `^[a-z][a-z0-9_-]{0,31}$`, password + confirm via `tui_password` (no complexity enforcement)

### Step 7 — Disk setup

**Auto path** (`step_disk_auto`):
1. Disk picker from `lsblk -d -p -n -o NAME,SIZE,MODEL` (excludes loop/sr/rom)
2. Red warning + "Type 'yes' to confirm"
3. Optional swap (`tui_yesno` + size GB, default 4)
4. **Partitioning with progress display** (output → PROGRESS_LOG, background redraw loop):
   - UEFI: `sgdisk -Z` wipe → GPT → EFI 1024M (ef00) → swap (8200, optional) → root rest (8300)
   - BIOS: GPT → BIOS boot 1M (ef02) → swap → root
   - `partprobe` + sleep 2
5. Format: `mkfs.vfat -F 32` (EFI), `mkswap` (swap), `mkfs.ext4 -F` (root)
6. Mount: root → `/mnt/archinstall`, EFI → `/mnt/archinstall/boot`, `swapon`

**Manual path** (`step_disk_manual`):
- Prints instructions per boot mode (EFI ≥512MB → mount /boot; swap optional; root ext4)
- Drops to shell (`bash`); on return verifies `mountpoint /mnt/archinstall` (+ `/boot` for UEFI) else `die`
- Derives INSTALL_DISK from `findmnt` (strips partition number + p suffix)

### Step 8 — Base install

1. Writes `vconsole.conf` KEYMAP early
2. base_pkgs: base, linux, linux-firmware, grub, efibootmgr, networkmanager, sudo, vim, nano, git, zsh, base-devel, amd-ucode, intel-ucode, libnewt, pciutils, curl, wget
3. `reflector --latest 10 --protocol https --sort rate` (120s timeout) → mirrorlist copied into target
4. `pacstrap -K` with **3 retries** (re-runs reflector between retries)
5. `genfstab -U` → fstab

### Step 9 — Chroot system config (progress-displayed)

1. timezone: symlink `/usr/share/zoneinfo/$TZ` → `/etc/localtime`, `hwclock --systohc`
2. **Locale design:** LANG=en_US.UTF-8 always (UI/logs English), LC_TIME=user locale (regional dates). `enable_locale()` uncomments locale.gen entries (handles both `name.UTF-8` and bare `name` forms), always en_US + user's; `locale-gen`; resolves canonical name via `locale -a`; writes locale.conf
3. vconsole KEYMAP; hostname + hosts (127.0.1.1 hostname.localdomain)
4. root + user passwords via `chpasswd`; `useradd -m -G wheel`; `%wheel ALL=(ALL:ALL) ALL` sudo
5. pacman.conf: Color, ParallelDownloads, VerbosePkgLists, multilib enabled
6. **GRUB** (most failure-prone): UEFI → `grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB`; BIOS → `grub-install --target=i386-pc $DISK`; then `grub-mkconfig` (failures logged, non-fatal)
7. `systemctl enable NetworkManager`

### Step 10 — HyprFlux first-boot prep

1. Copies live resolv.conf into target (needed for chroot git)
2. Clones **base-installer** and **HyprFlux** into `/home/$USER/` (300s timeout each, progress-displayed, fatal on failure)
3. `chown -R user:user /home/$USER`
4. Writes `~/.hyprflux-firstboot.sh` (not executable — sourced from .bash_profile):
   - Marker-gated (`~/.hyprflux-install-done`), tty1-gated
   - Centered ASCII "Welcome to HyprFlux!" panel
   - `bash ~/HyprFlux/install.sh` (the FULL manual flow = base-installer + dotsSetup)
   - On success: touch marker + "To start Hyprland desktop, type: Hyprland"
   - On failure: instructions to re-run manually
   - Self-removes its .bash_profile line
5. Writes `~/.bash_profile`: sources .bashrc; on tty1 without marker → source firstboot

### Step 11 — Cleanup & reboot

- Success box, instructions (remove USB, login as $USER, installer auto-runs, 20-60 min, don't interrupt, then type Hyprland)
- `umount -R /mnt/archinstall`, `swapoff -a`, 5s countdown → `reboot`

---

## 7.7 The TUI framework — `lib/tui.sh` (654 lines)

**Design contract (from header):** every screen = clear → banner → content; all text indented by `$PAD` (spaces) to align with the 66-column banner; cursor hidden by default (shown only during gum input); long ops write to a log file with a background full-redraw loop (no cursor save/restore → no flicker).

| Function | Purpose |
|----------|---------|
| `_compute_layout` | stty size → TERM_WIDTH/HEIGHT, PADDING_LEFT = (width-66)/2 |
| `check_terminal_size` | warns if < 80x24 |
| `_build_banner_cache` | pre-builds banner string: cyan H Y P R F L U X ASCII logo (6 lines) + red `✻───ahmad9059───✻` separator + green welcome line |
| `show_banner` | hide cursor, clear, print cached banner |
| `set_status` | yellow status line under banner |
| `tui_print*`, `log_step/ok/warn/error/cmd/info` | centered output + log labels |
| `tui_spinner` | inline ASCII spinner (`/-\|` — no UTF-8 issues on early console) around a background command, then [OK]/[ERROR] |
| `tui_wait` | timed spinner delay |
| `start_progress`/`_progress_loop`/`stop_progress` | full-screen progress: banner + status row 11 + log rows 13+ (max 25 lines, 58-char truncation, ANSI-stripped in pure bash, in-place updates with erase-EOL) |
| `run_with_progress`, `run_cmd` | wrappers |
| `tui_menu` | gum choose (PAD-prefixed header/cursor, height 15) |
| `tui_yesno` | gum choose Yes/No (gum confirm can't be indented) |
| `tui_input` | gum input with placeholder default |
| `tui_password` | gum input --password |
| `tui_search` | gum filter (type-to-search, height 20) |
| `tui_multiselect` | gum choose --no-limit |
| `tui_msg`/`tui_error` | Enter-to-continue messages |
| `tui_success_box`/`warning_box`/`info_box` | gum style rounded boxes with margin indent |
| `_tui_cleanup` | EXIT trap: kill progress, show cursor |
| `dlg_*` aliases | backward-compat (menu/yesno/input/password/msgbox/search/checklist/radiolist) |

## 7.8 `lib/common.sh` (182 lines)

- `MOUNT_POINT=/mnt/archinstall`; installer variable defaults via `: "${VAR:=}"`
- `die()` — kills progress, clears log, resets terminal, banner, error message, **drops to bash shell**, exit 1
- Validation: `validate_hostname`, `validate_username`, `validate_password`
- Network: `check_internet`, `wait_for_internet` (30 attempts)
- Detection: `detect_boot_mode`, `detect_nvidia` (lspci)
- Disk: `get_part_prefix` (nvme/mmcblk → `p` suffix), `list_disks`
- `setup_mirrors` — reflector (latest 20, https, rate, 120s)

## 7.9 The chroot wrapper — `lib/hyprflux-chroot-wrapper.sh` (544 lines)

The documented target integration (implemented but the live installer currently uses the first-boot path).

### Phase 0 — Shims (operations that fail in chroot)

| Shim | Mechanism |
|------|-----------|
| systemctl | real → `/usr/bin/systemctl.real`; shim at `/usr/bin/systemctl`: strips `--now`, skips runtime verbs (start/stop/restart/reload/status), tries `--user enable` for user units, logs `[shim]` messages |
| chsh | `/usr/local/bin/chsh` no-op (shell set via `usermod` later) |
| gsettings | no-op (no dbus in chroot; deferred to first-boot) |
| nwg-look | no-op (no display in chroot) |
| sudoers | temp `/etc/sudoers.d/hyprflux-temp` passwordless sudo for target user |
| shell | pre-set `/bin/bash` so `su -` works before zsh exists |

### Phase A — base-installer scripts (A1–A16)

`run_as_user()` runs each via `su - $USER -s /bin/bash -c` with HOME/PATH exported; failures are warned-not-fatal.
A1 00-base → A2 pacman → A3 yay (with Global_functions.sh ISAUR patch + `/usr/local/bin/yay-iso` wrapper + PATH symlink fallback) → A4 01-hypr-pkgs → A5 pipewire → A6 fonts → A7 hyprland → A8 bluetooth → A9 sddm → A10 nvidia (conditional on detection) → A11 zsh → A12 thunar → A13 xdph → A14 *(removed)* → A15 dotfiles-main (verifies base-dots; config deploy = module 02 only) → A16 02-Final-Check.

### Phase B — HyprFlux modules

- Writes `/tmp/hyprflux-module-env.sh` (HYPRFLUX_ISO_MODE=1, SDDM_THEME, GRUB_THEME_DIR, GTK_THEME, ICON_THEME, CURSOR_THEME, FONT_NAME, WAYBAR_STYLE, TERMINAL, BROWSER…)
- Sourced per-module as target user; `08-gtk.sh` deferred (gsettings needs dbus), `17-optional-packages.sh` skipped (interactive)

### Phase C — Services

- Restore real systemctl; `usermod -s zsh`; ensure sddm (check service unit, install fallback); enable sddm + bluetooth + NetworkManager; `set-default graphical.target`

### Phase D — First-boot fixup

- `~/.config/autostart/hyprflux-first-boot.desktop` → `~/.local/bin/hyprflux-first-boot.sh`:
  - marker-gated (`~/.config/hyprflux-first-boot-done`), waits 3s for desktop
  - gsettings GTK theme/icons/cursor/font/dark; `nwg-look -a`; enable pipewire user units
  - removes itself + notifies

### Cleanup

- Remove shims, temp sudoers, yay-iso, env file; restore Global_functions.sh.bak; rm Install-Logs

---

## 7.10 ISO build & test tooling

### build.sh

1. Root check (mkarchiso requires root); auto-install archiso if missing
2. Verifies profiledef.sh in cwd
3. `rm -rf work out; mkdir out`
4. `mkarchiso -v -w work -o out .` (5-15 min)
5. Report ISO path/size + sha256sum file
6. Optional work-dir cleanup prompt

### test-qemu.sh

- Args: `--uefi` (default) / `--bios`, `--ram=N` (default 8G), `--cpus=N` (4), explicit ISO path
- QEMU cmd: KVM, `-cpu host`, virtio-vga-gl, virtio-net user networking, intel-hda audio, usb-tablet, GTK display with GL
- UEFI: OVMF_CODE.4m.fd read-only + fresh OVMF_VARS copy; BIOS: no firmware drives
- Fresh 40G qcow2 test disk (`/mnt/vmachines/images/hyprflux-test-disk.qcow2`) each run

### CI — `.github/workflows/build-iso.yml`

```
on: push main, v* tags, PR, workflow_dispatch
job build-iso: ubuntu-latest + archlinux:latest privileged container
  pacman -Syu; pacman -S archiso grub git
  mkarchiso -v -w work -o out .
  sha256sum; upload artifact (14 days, compression 0)
job release (needs build-iso, tags only):
  download artifact → softprops/action-gh-release v2
  body: install instructions (dd), features, verify sha256, requirements
  prerelease flag if tag contains alpha/beta
```

---

# PART 8 — RELATED REPOS

## 8.1 nvim (github.com/ahmad9059/nvim)

Separate maintained Neovim distribution. Cloned by module 04 into `~/.config/nvim`, then `Lazy sync` + Mason install headless. Contents: lazy.nvim plugin manager, LSP/Mason toolchain, language configs. (Not deep-dived here — out of scope of dotfiles architecture.)

## 8.2 wallpapers-bank (github.com/ahmad9059/wallpapers-bank)

Wallpaper collection cloned by module 13 to `~/Pictures/wallpapers`. Consumed by: WallpaperSelect.sh (rofi grid), WallpaperRandom.sh, WallpaperAutoChange.sh (awww daemon), initial-boot.sh default wallpaper (`wallpaper-5.jpg`).

## 8.3 base-dots (merged)

Merged into the HyprFlux repo (2026-08-25) at `base-dots/`. Its `copy.sh` remains as a standalone manual tool, but **the install flow no longer runs it**: `base-dots/config` is byte-identical to `.config/` (CI parity gate), so config deployment is done exactly ONCE by dotsSetup module 02 (`.config/` → `~/.config/`). `dotfiles-main.sh` only verifies the merged checkout and warns on drift. ags/quickshell/wallust configs removed (apps removed from HyprFlux); bundled wallpapers removed (module 13 wallpapers-bank is the single source).

---

# PART 9 — INSTALL FLOWS (END-TO-END, BOTH PATHS)

## 9.1 Path A — ISO (bare metal)

```
1. Download ISO (from CI release) → dd to USB:
     sudo dd bs=4M if=hyprflux-*.iso of=/dev/sdX status=progress oflag=sync
2. Boot USB.
   UEFI: firmware → GRUB (HyprFlux theme) → "HyprFlux Installer" entry
   BIOS: firmware → syslinux → same kernel/initramfs
   cmdline: archisobasedir=hyprflux archisosearchuuid=... cow_spacesize=2G quiet splash
3. Plymouth splash → live Arch env (root auto-login tty1)
4. .zlogin → hyprflux-install.sh (TUI):
   [Step 0] network (ethernet/wifi/manual)
   [Step 1] welcome confirm
   [Step 2] timezone (auto-detect or search)
   [Step 3] locale (search)
   [Step 4] keyboard (common or all)
   [Step 5] hostname
   [Step 6] username + password
   [Step 7] disk: automatic (wipe + optional swap) OR manual (shell)
   [Step 8] reflector + pacstrap base (3 retries) + fstab
   [Step 9] chroot: timezone/locale(EN LANG + regional LC_TIME)/keymap/hostname/
            users/sudo/pacman.conf/GRUB/NetworkManager
   [Step 10] clone base-installer + HyprFlux into /home/<user>/
             write .hyprflux-firstboot.sh + .bash_profile hook
   [Step 11] unmount → reboot
5. First boot → SDDM? NO — tty1 login → .bash_profile → .hyprflux-firstboot.sh
   → bash ~/HyprFlux/install.sh
6. install.sh: pacman -Syu → clone/run base-installer (patched, automated:
   base-devel, pacman spices, yay, Chaotic-AUR via initial.sh, Hyprland pkgs,
   pipewire, fonts, hyprland, sddm, zsh, thunar, xdph, base-dots verify
   pre-patched, HyprFlux zsh.sh) → dotsSetup.sh (19 modules:
   backup, dotfiles, packages, nvim, themes, waybar, sddm, gtk, grub, plymouth,
   tmux, zsh patch, wallpapers, webapps, bibata, ai-tools, optional, monitors)
7. Second reboot → SDDM (HyprFlux theme, sugar-candy fallback) → graphical.target
   → login → first-boot fixup autostart (gsettings, nwg-look, pipewire user svc)
   → type Hyprland (or session auto-select) → full desktop
```

## 9.2 Path B — Manual (existing Arch)

```
1. sh <(curl -fsSL https://hyprflux.dev/install)        [or git clone + bash install.sh]
2. Bootstrap: git → clone HyprFlux to ~/HyprFlux → exec real install.sh
3. Logging ~/hyprflux_log/, sudo keep-alive, banner, pacman -Syu
4. Clone base-installer (~/base-installer)
5. Run merged base-installer install.sh (pre-patched, no whiptail prompts); run
   (cd base-installer && bash install.sh)  → same automated base install as above
6. dotsSetup.sh  → 19 modules (as above; optional packages prompt interactively)
7. Reboot prompt → SDDM → HyprFlux desktop (first-boot initial-boot.sh applies
   wallpaper/GTK/kvantum one-shot on live machines)
```

**Both paths converge at `HyprFlux/install.sh` → `dotsSetup.sh` → 19 modules.** The ISO only adds: base OS installation + repo pre-cloning + auto-trigger.

## 9.3 What a finished system has

- Hyprland (Lua config) + Waybar + Rofi + SwayNC + Wlogout + Kitty/Foot
- SDDM (HyprFlux theme), GRUB (HyprFlux theme), Plymouth (hyprflux)
- GTK: HyprFlux-Compact theme, Papirus-Dark cyan icons, Future-black + Bibata cursors
- Chaotic-AUR + yay; AI tools (claude-code, opencode-bin, openai-codex-bin)
- Neovim (Lazy/Mason), tmux+tmuxifier, zsh+oh-my-zsh (refined theme)
- Chromium PWAs (Netflix/WhatsApp/ChatGPT/YouTube/GitHub), wallpapers-bank
- Auto-detected monitor config (monitors.lua + profiles)
- Backup of prior dotfiles in ~/dotfiles_backup; install logs in ~/hyprflux_log/

---

# PART 10 — CI/CD SUMMARY

| Repo | Workflow | Triggers | What it does |
|------|----------|----------|--------------|
| HyprFlux | config-check.yml | push/PR on `.config/hypr/**`, `utilities/sync-colors.sh`, waybar/rofi/swaync/kitty/foot paths | archlinux container; `luac -p` every Lua; `Hyprland --verify-config` (with XDG_RUNTIME_DIR exported to /tmp/hypr-runtime); sync-colors freshness gate |
| HyprFlux-ISO | build-iso.yml | push main, `v*` tags, PR, manual | privileged archlinux container; install archiso+grub; `mkarchiso`; sha256; artifact 14 days; release on tags with dd instructions |

---

# PART 11 — KEY DESIGN DECISIONS & GOTCHAS

## 11.1 Design decisions

1. **Convergence:** ISO + manual paths both terminate in the same `install.sh` — one pipeline to maintain.
2. **Online-only install:** nothing pre-baked beyond the live env; everything clones from GitHub at install time (keeps ISO small, always-fresh).
3. **Merge-don't-clone (2026-08-25):** base-installer and base-dots are merged into this repo with all automation patches baked in — no runtime patching, no extra clones, one repo to manage. Both keep their GPL-3.0 LICENSE.md.
4. **Chroot shims** solve the systemctl/gsettings/chsh/nwg-look-in-chroot problem without forking upstream scripts.
5. **Lua-first config:** Hyprland ≥ 0.55 mandates Lua (legacy `hypr_old/` archive removed 2026-08-26); nwg-displays owns monitors.lua/workspaces.lua.
6. **Single color source:** one `.conf` → 6 generated files + 2 injected blocks; CI enforces freshness; nothing hand-edited downstream.
7. **Module sourcing:** modules are `source`d (shared scope) → SKIP_MODULES + env overrides give full control; same orchestrator powers full installs and granular re-runs.
8. **Resilience:** every cosmetic step (plymouth, grub theme, SDDM theme) is non-fatal; retries everywhere (pacman 5×, pacstrap 3×, git clone 5×); verbose logs for every stage.
9. **First-boot split:** chroot can't do dbus/display work → deferred to marker-gated first-boot autostart.

## 11.2 Known gotchas (from code comments + work log)

- `hyprctl dispatch <old-hyprlang-string>` broken in Lua mode → use `hl.dsp.*` / `hyprctl eval`
- `XF86AudioPlayPause` not valid in Lua API → keycode `code:164`
- Lua API caps animation speed at 100 ds (hyprlang allowed 180)
- `workspaceopt allfloat` no longer works in Lua → native Lua implementation
- `gum confirm` cannot be indented → `tui_yesno` uses gum choose
- UTF-8 spinners break on early console → ASCII `/-\|`
- syslinux/GRUB must use `archisobasedir=%INSTALL_DIR%` because install_dir ≠ "arch"
- Chroot has no PCI bus → NVIDIA detection must run on live env
- Global_functions.sh `ISAUR` line needs patching in chroot (PATH issue)
- `RofiEmoji.sh` fails `bash -n` but works (self-extracting data after exit)
- GTK4 cannot `@import` CSS → color blocks injected directly into swaync/wlogout style.css
- nwg-displays ≥ 2.4 overwrites monitors.lua with its own output (installer writes it first)
- Waybar `hyprctl dispatch hl.dsp...` click-handling requires `waybar-git` from chaotic-aur (PR #5013)

---

# PART 12 — CURRENT STATE (2026-08-24)

## 12.1 Main repo

- Full hyprlang→Lua migration complete and committed; live machine runs Lua (`dispatcher: __lua`, 152 binds verified)
- `docs/plan/progress.md` + `docs/WORK-LOG.md` track all work
- CI config-check workflow green (validated locally)
- Working tree clean; repo ↔ live in sync for all managed configs

## 12.2 ISO repo

- Fully implemented: TUI installer (1065 lines), TUI framework (654), chroot wrapper (544), GRUB + Syslinux + systemd-boot entries, Plymouth theme, CI
- Last ISO build: `hyprflux-2026.08.12-x86_64.iso` (~1.1 GB) in `out/`
- Implementation followed the 6 phase plans in `plans/` (18 issues found and fixed during plan review)
- Current live installer uses the **first-boot path** (clone repos + .bash_profile hook); the chroot-wrapper approach remains implemented in-tree as the documented target

## 12.3 Machine-specific (live-only, not in repo)

- `~/.config/hypr/scripts/initial-boot.sh` — one-shot first-boot setup (wallpaper, GTK dark, kvantum, keyboard layout), marker-gated at `~/.config/hypr/.initial_startup_done`, referenced from `hyprland.lua`
- `~/.config/hypr/scripts/refresh-rate.sh` — 165 Hz AC / 60 Hz battery daemon via `hypr-refresh-rate.service` (systemd user unit), restarted at login from startup-apps.lua
- These reference local hardware (eDP-1, AC0, AQ_DRM_DEVICES card2/card1) and are intentionally kept live-only so the distro stays generic

---

*End of report. Generated from full source analysis of all repos on 2026-08-24.*