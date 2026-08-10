-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- HyprFlux static color palette (Lua module, Hyprland >= 0.55)
--
-- Replaces: hyprflux-colors/hyprflux-colors.conf
-- The old .conf file is KEPT until the entrypoint flip (hyprlock/hypridle
-- still read hyprlang and UserDecorations.conf still sources it).
--
-- Usage from any config module:
--   local colors = require("hyprflux-colors")
--   hl.config({ general = { col = { active_border = colors.color12 } } })
--
-- Colors are normalized to rgba() with explicit opaque alpha (identical
-- rendering to the old rgb() form, but alpha-tunable when needed).

local colors = {
    background = "rgba(010102ff)",
    foreground = "rgba(FDF8FEff)",
    color0 = "rgba(313131ff)",
    color1 = "rgba(09050Cff)",
    color2 = "rgba(221647ff)",
    color3 = "rgba(2C1A40ff)",
    color4 = "rgba(5E3887ff)",
    color5 = "rgba(7344A6ff)",
    color6 = "rgba(BAB0BDff)",
    color7 = "rgba(F3ECF5ff)",
    color8 = "rgba(AAA5ACff)",
    color9 = "rgba(0B0711ff)",
    color10 = "rgba(2D1D5Fff)",
    color11 = "rgba(3B2355ff)",
    color12 = "rgba(7D4AB4ff)",
    color13 = "rgba(9A5BDDff)",
    color14 = "rgba(F8EAFCff)",
    color15 = "rgba(F3ECF5ff)",
}

return colors
