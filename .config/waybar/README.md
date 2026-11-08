# HyprFlux Waybar

## File layout

| File | Purpose |
| --- | --- |
| `config` | Small entrypoint selecting one preset. Put personal layout overrides here. |
| `configs/HyprFlux-Default-Laptop` | Original layout: visualizer/media/window left, workspaces/clock/weather center, app and system drawers right. Battery/backlight depend on available hardware. |
| `UserModules` | Personal module overrides; loaded **before** shared definitions. First defined value wins, including nested keys. |
| `Modules` | Native Waybar modules. |
| `ModulesWorkspaces` | Named workspace appearance variants. Native click handling; optional Lua-compatible scroll commands. |
| `ModulesCustom` | Application launchers and custom JSON/stream modules. |
| `ModulesGroups` | Reusable groups and hover drawers. |
| `ModulesVertical` | Optional vertical module variants; not a separate layout. |
| `style.css` | Theme entrypoint. |
| `style/HyprFlux-Default.css` | Original typography, rounded sections and Catppuccin Mocha module colors. |
| `hyprflux-colors.css` | Generated palette. Edit `hypr/hyprflux-colors/hyprflux-colors.conf`, then run `utilities/sync-colors.sh` from the repository. |

The extensionless configuration files use JSON/JSONC, **not Lua**. Keep names
stable: personal presets may already include these module banks.

## Customize without editing shared defaults

For a 24-hour clock and simpler workspace labels, edit `UserModules`:

```json
{
  "clock": {"format": " {:%H:%M}"},
  "hyprland/workspaces#rw": {"format": "{name}"}
}
```

The original layout is selected by `config`:

```json
{
  "include": ["$HOME/.config/waybar/configs/HyprFlux-Default-Laptop"]
}
```

You can instead keep the default include and set `modules-left`,
`modules-center`, or `modules-right` in `config`; entrypoint values take
precedence over the preset. Arrays replace the entire list, not individual items.
Do not put layout overrides in `UserModules`: the including preset's own layout
has higher precedence. The original spacers and module placement are retained
at the user's request; the audit's alternate visual layout was withdrawn.

Personal monitor assignments belong in `UserModules`, using your actual output
names from `hyprctl monitors`. Do not bake one laptop's output names into the
shared defaults. Five persistent workspaces per output are the generic default.

Reload only your own bars:

```bash
pkill -u "$UID" -USR2 -x waybar
```

CSS changes also reload automatically. Drawers reveal their children on hover.

## Default controls

- **Hyprland logo:** application launcher; middle click opens wallpapers.
  Hover reveals files, terminal, browser and quick settings.
- **Workspaces:** native Waybar click handling. The default window-icon variant
  disables scroll to prevent accidental changes. Scroll-enabled variants pass a
  single quoted Lua dispatcher expression to Hyprland.
- **Media:** original custom/playerctl placement, hidden without a player.
  Left click previous, middle play/pause, right next. Titles/artists now use
  serialized JSON. Native `mpris` is also available for personal layouts.
- **Clock:** left click toggles date/time format; scroll moves the calendar.
- **Eye:** idle inhibitor, not a system-wide override of lid/power policy.
- **Network:** the tray applet remains in the original layout. Optional
  `group/connections` provides nmtui on click and Bluetooth controls on hover.
- **Brightness:** scroll adjusts it. Battery right click opens the power menu.
- **Temperature:** hover reveals CPU/profile/memory/disk. Right click opens nvtop;
  CPU/memory right click opens btop. Missing optional tools report an error rather
  than installing anything.
- **Audio:** click mutes, scroll adjusts volume, right click opens the mixer.
  Hover reveals microphone controls.
- **Updates:** official repository count only. Left click starts the existing
  interactive system updater; right click refreshes the count. Error/unknown
  states are distinct from “up to date”; AUR updates are not counted.
- **Notifications:** click opens SwayNC, right click toggles Do Not Disturb.
- **Power:** opens wlogout; no immediate shutdown on the default bar.

## Helpers and resource use

`hypr/scripts/WaybarStatus.py` delegates to `hyprflux/waybar.py`. It handles
updates, application launching, optional Cava, and compatibility JSON modules.
`WaybarScripts.sh` and `WaybarCava.sh` retain their existing public names.

Update checks run hourly; multiple monitors share a locked five-minute cache.
`checkupdates` exit code 2 means no updates, not failure. Other errors/timeouts
show an explicit warning. A successful interactive update invalidates the cache
and signals the current user's bars. Reloading Waybar does **not** install or
upgrade packages.

The main clock updates once a minute and CPU every five seconds. Cava remains
enabled in the original left section. Each instance owns a private config
and one child process, renders at 15 fps, and cleans up only its own child.
It never kills other bars' visualizers or uses a shared `/tmp/bar_cava_config`.

`custom/playerctl` and `custom/keyboard` use JSON serialization rather than
interpolated metadata or a stale cache file. The default avoids `/dev/input`
keyboard-state access. The native `mpris` and `hyprland/language` modules remain
available as alternatives without forcing a visual redesign.

App launching reads literal `term`/`files` values in
`hypr/UserConfigs/user-defaults.lua` without executing Lua or shell fragments.
Tool launching supports Kitty, Foot/footclient, Alacritty and Ghostty, including
configured arguments. Unknown terminal adapters fail clearly.

## Hardware and compatibility

The default temperature config looks for common AMD/Intel CPU device directories,
not changing `hwmonN` numbers. The hardware-detection installer selects the actual
sensor by driver name and updates both horizontal/vertical native module banks.
On unsupported hardware the temperature module may be unavailable; override it
in `UserModules` with the actual sensor identity. Do not confuse a motherboard,
SSD or Wi-Fi temperature with CPU temperature.

Use a Waybar build with **Hyprland Lua IPC support** for this repository's Lua
Hyprland configuration. The installed `0.16.0-2-gf49ec82e` build was checked for
native Lua dispatch translation. Do not paste `hl.dsp` expressions into shell
commands without quoting, or treat `$WORKSPACE_ID` as a supported Waybar variable.

Required components include Waybar, Python, Nerd Font icons, the normal HyprFlux
desktop helpers, NetworkManager/nmtui, PulseAudio-compatible PipeWire, and
playerctl/playerctld for native MPRIS. `pacman-contrib` provides checkupdates;
Cava, btop and nvtop are optional. Network weather requests have bounded timeouts
and produce a valid unavailable state on failure.

## Tests and source mirror

From the repository root:

```bash
python -m unittest discover -s tests -p 'test_waybar.py' -v
python -m unittest discover -s tests -v
```

Tests cover includes/precedence, duplicate keys, groups, shell syntax, helper
paths, GTK3 CSS, cache/errors, metadata escaping, terminal argv, independent Cava
instances, weather, sensor configuration, installer preservation, and
`.config`/`base-dots/config` parity. They do not install packages or change power,
network or audio settings. A live bar check is still necessary after substantial
Waybar/Hyprland updates.

Maintain the matching `base-dots/config/waybar` and helper copies whenever shared
source changes. The legacy base-dots upgrade path now handles Waybar once and
preserves `UserModules`, unique presets/styles and valid relative selections.
This does not turn the general dotfiles replacement module into a nondestructive
personal-config merger: always keep a backup before reinstalling/upgrading.
