-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- old animations
--
-- Lua animation preset (Hyprland >= 0.55). Copied by Animations.sh
-- over UserConfigs/user-animations.lua, then applied via `hyprctl config full-reload`.
--
-- NOTE: Lua API caps animation speed at 100 ds (hyprlang allowed 180).

hl.config({ animations = { enabled = true } })
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("linear", { type = "bezier", points = { {0.0, 0.0}, {1.0, 1.0} } })
hl.curve("wind", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("winIn", { type = "bezier", points = { {0.1, 1.1}, {0.1, 1.1} } })
hl.curve("winOut", { type = "bezier", points = { {0.3, -0.3}, {0, 1} } })
hl.curve("slow", { type = "bezier", points = { {0, 0.85}, {0.3, 1} } })
hl.curve("overshot", { type = "bezier", points = { {0.7, 0.6}, {0.1, 1.1} } })
hl.curve("bounce", { type = "bezier", points = { {1.1, 1.6}, {0.1, 0.85} } })
hl.curve("sligshot", { type = "bezier", points = { {1, -1}, {0.15, 1.25} } })
hl.curve("nice", { type = "bezier", points = { {0, 6.9}, {0.5, -4.20} } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "slow", style = "popin" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "popin" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "linear" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop " })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "overshot" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "bounce", style = "popin" })
