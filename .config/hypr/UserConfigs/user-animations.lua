-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Animation Settings (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/UserAnimations.conf
-- Wiki: https://wiki.hypr.land/Configuring/Animations/
--
-- Speed is in ds (1 ds = 100 ms). hyprlang `animation = windows, 1, 6, wind, slide`
-- becomes `hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })`.

hl.config({ animations = { enabled = true } })

-- Curves (hyprlang `bezier = name, x1, y1, x2, y2`)
hl.curve("wind",      { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05} } })
hl.curve("winIn",     { type = "bezier", points = { {0.1, 1.1},   {0.1, 1.1} } })
hl.curve("winOut",    { type = "bezier", points = { {0.3, -0.3},  {0, 1} } })
hl.curve("liner",     { type = "bezier", points = { {1, 1},       {1, 1} } })
hl.curve("overshot",  { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05} } })
hl.curve("smoothOut", { type = "bezier", points = { {0.5, 0},     {0.99, 0.99} } })
hl.curve("smoothIn",  { type = "bezier", points = { {0.5, -0.5},  {0.68, 1.5} } })

-- Animations
hl.animation({ leaf = "windows",       enabled = true, speed = 6,   bezier = "wind",      style = "slide" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,   bezier = "winIn",     style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3,   bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 5,   bezier = "wind",      style = "slide" })
hl.animation({ leaf = "border",        enabled = true, speed = 1,   bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "liner", style = "loop" }) -- used by rainbow borders / rotating colors. NOTE: Lua API caps speed at 100 (old hyprlang value was 180 = 18s per rotation; now 10s)
hl.animation({ leaf = "fade",          enabled = true, speed = 3,   bezier = "smoothOut" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5,   bezier = "overshot" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 5,   bezier = "winIn",     style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 5,   bezier = "winOut",    style = "slide" })
