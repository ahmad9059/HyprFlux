-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- name "Standard"
-- credit https://github.com/mylinuxforwork/dotfiles
--
-- Lua animation preset (Hyprland >= 0.55). Copied by Animations.sh
-- over UserConfigs/user-animations.lua, then applied via `hyprctl config full-reload`.
--
-- NOTE: Lua API caps animation speed at 100 ds (hyprlang allowed 180).

hl.config({ animations = { enabled = true } })
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
