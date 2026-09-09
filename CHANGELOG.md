# Changelog

All notable HyprFlux changes are documented here.

## [1.5.0] - 2026-09-09

HyprFlux 1.5.0 is a production-focused platform release spanning the desktop,
installer, live ISO, boot experience, hardware setup, and project tooling.

### Highlights

- Migrated the maintained Hyprland configuration from Hyprlang fragments to
  Lua, including keybinds, rules, workspaces, monitors, animations, startup,
  environment, laptop, decoration, and user-default configuration.
- Merged the base installer and base dotfiles into this repository so direct
  and ISO installations use one versioned source tree.
- Added the full HyprFlux ISO installation path with branded UEFI and Legacy
  BIOS menus, a guided TUI, automatic and manual partitioning, and complete
  in-chroot desktop provisioning.
- Replaced the SWWW wallpaper stack with AWWW and added wallpaper selection,
  effects, randomization, automatic rotation, and video wallpaper support.
- Added hardware-aware configuration for graphics, virtualization, laptops,
  power profiles, input devices, and monitor layouts.

### Installer And Reliability

- Consolidated package installation into ordered, batched phases with unified
  logs under `~/HyprFlux/logs/`.
- Added per-package recovery when a batch fails and protected package checks
  from premature background-process completion.
- Added repository-to-AUR fallback for packages affected by binary mirror
  failures; one failed AUR package no longer skips the remaining package list.
- Improved Yay bootstrap, Chaotic-AUR setup, dependency handling, shell setup,
  dotfile deployment, and idempotent reruns.
- Added resilient GRUB and Plymouth installation, boot artifact verification,
  first-boot completion handling, and recovery diagnostics.

### Desktop

- Updated configuration syntax for current Hyprland releases.
- Refined Waybar modules, workspace behavior, layouts, and the default
  HyprFlux color integration.
- Updated Rofi, SwayNC, Wlogout, Hyprlock, Kitty, Foot, Yazi, Fastfetch, Cava,
  GTK, Qt, Kvantum, cursor, and font configuration.
- Added or improved screenshot, brightness, volume, media, keyboard layout,
  game mode, drop terminal, weather, clipboard, and quick-settings scripts.
- Removed the AGS/Quickshell desktop layer and obsolete duplicate scripts,
  themes, images, and configuration paths.

### Platform And Tooling

- Added HyprFlux distribution identity across Fastfetch, GRUB, Plymouth, SDDM,
  the live ISO, and desktop assets.
- Added Neovim, Tmuxifier, Zsh, Yazi, web-app, and AI command-line tooling setup.
- Added repository configuration checks, Lua language-server configuration,
  installation architecture documentation, migration guides, work logs,
  contribution guidance, a code of conduct, and a security policy.
- Added compatibility fixes contributed for newer Hyprland configuration and
  media notification behavior.

### Important Upgrade Notes

- Hyprland user overrides now use Lua files. Existing `.conf` customizations
  should be migrated rather than copied over the new defaults.
- SWWW commands and custom scripts should be replaced with their AWWW
  equivalents.
- Quickshell and AGS configuration is no longer part of the default desktop.
- A fresh installation is recommended for the cleanest 1.5.0 experience.

[1.5.0]: https://github.com/ahmad9059/HyprFlux/releases/tag/v1.5.0
