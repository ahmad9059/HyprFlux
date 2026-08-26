-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Decoration Settings (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/UserDecorations.conf
-- Wiki: https://wiki.hypr.land/Configuring/Variables/

local colors = require("hyprflux-colors")

hl.config({
    general = {
        border_size = 2, -- live machine value (repo default was 0)
        gaps_in = 2,
        gaps_out = 4,

        col = {
            active_border = colors.color12,
            inactive_border = colors.color10,
        },
    },

    decoration = {
        rounding = 10,

        active_opacity = 1.0,
        inactive_opacity = 0.9,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.1,
        dim_special = 0.8,

        shadow = {
            enabled = false,
            range = 3,
            render_power = 1,

            color = colors.color12,
            color_inactive = colors.color10,
        },

        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            ignore_opacity = true,
            new_optimizations = true,
            special = false, -- expensive; rarely noticed
            popups = true,
        },
    },

    group = {
        col = {
            border_active = colors.color15,
        },

        groupbar = {
            col = {
                active = colors.color0,
            },
        },
    },
})
