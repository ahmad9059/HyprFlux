# HyprFlux — Legacy hyprlang config (`.conf`)

**This folder is the pre-Lua Hyprland configuration, kept for reference.**

Since Hyprland 0.55, hyprlang (`.conf`) is deprecated in favor of Lua
(`hyprland.lua`). The active config lives in `../hypr/`. Everything in this
folder is the old hyprlang syntax from dots version `v2.3.16`.

| What | Where (new) |
|---|---|
| `hyprland.conf` (entrypoint) | `../hypr/hyprland.lua` |
| `configs/Keybinds.conf` | `../hypr/configs/keybinds.lua` |
| `UserConfigs/*.conf` (13 files) | `../hypr/UserConfigs/*.lua` |
| `monitors.conf` | `../hypr/monitors.lua` (nwg-displays generated) |
| `workspaces.conf` | `../hypr/workspaces.lua` (nwg-displays generated) |
| `animations/*.conf` (16 presets) | `../hypr/animations/*.lua` |
| `Monitor_Profiles/default.conf` | `../hypr/Monitor_Profiles/default.lua` |
| `v2.3.16` (version marker) | `../hypr/v2.4.0` |

NOT duplicated here (still in active use, hyprlang by design):

- `../hypr/hyprlock.conf`, `../hypr/hyprlock-1080p.conf` (hyprlock — never converted)
- `../hypr/hypridle.conf` (hypridle — never converted)
- `../hypr/application-style.conf` (hyprland-qt-support)
- `../hypr/hyprflux-colors/hyprflux-colors.conf` (sourced by hyprlock-1080p.conf)

If you ever need to roll back to the legacy config on a machine: copy
`hyprland.conf` back to `~/.config/hypr/` and delete `hyprland.lua`
(precedence is checked once at startup).

See `../plan/` in the repo docs for the full migration record.
