-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- name "Vertical"
-- credit https://github.com/prasanthrangan/hyprdots
-- Windows
-- Fading
-- Layers
-- Workspaces
--animation = workspaces, 1, 3, fluent_decel, slidefade 30% # styles: slide, slidevert, fade, slidefade, slidefadevert
--
-- Lua animation preset (Hyprland >= 0.55). Copied by Animations.sh
-- over UserConfigs/user-animations.lua, then applied via `hyprctl config full-reload`.
--
-- NOTE: Lua API caps animation speed at 100 ds (hyprlang allowed 180).

hl.config({ animations = { enabled = true } })
hl.curve("fluent_decel", { type = "bezier", points = { {0, 0.2}, {0.4, 1} } })
hl.curve("easeOutCirc", { type = "bezier", points = { {0, 0.55}, {0.45, 1} } })
hl.curve("easeOutCubic", { type = "bezier", points = { {0.33, 1}, {0.68, 1} } })
hl.curve("easeinoutsine", { type = "bezier", points = { {0.37, 0}, {0.63, 1} } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1.5, bezier = "easeinoutsine", style = "popin 60% " })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "easeOutCubic", style = "popin 60% " })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1.5, bezier = "easeinoutsine", style = "slide " })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "fluent_decel" })
hl.animation({ leaf = "layers", enabled = true, speed = 1.5, bezier = "easeinoutsine", style = "popin" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "fluent_decel", style = "slidefadevert 30% " })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, bezier = "fluent_decel", style = "slidefade 10%" })
