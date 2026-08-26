-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- name "Minimal-2"
-- credit https://github.com/prasanthrangan/hyprdots
--
-- Lua animation preset (Hyprland >= 0.55). Copied by Animations.sh
-- over UserConfigs/user-animations.lua, then applied via `hyprctl config full-reload`.
--
-- NOTE: Lua API caps animation speed at 100 ds (hyprlang allowed 180).

hl.config({ animations = { enabled = true } })
hl.curve("quart", { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "quart", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "quart" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "quart" })
