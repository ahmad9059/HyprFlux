-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- User Settings (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/UserSettings.conf
-- Wiki: https://wiki.hypr.land/Configuring/Variables/

hl.config({
    -- Layout options are flat config keys (dwindle.*, master.*), not layout.*
    dwindle = {
        -- pseudotile was removed in Hyprland 0.55 (did nothing)
        preserve_split = true,
        -- smart_split = true,
        special_scale_factor = 1,
    },
    master = {
        new_status = "master",
        new_on_top = 1,
        mfact = 0.5,
    },

    general = {
        resize_on_border = true,
        layout = "dwindle",
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "ctrl:nocaps", -- live machine value (repo default: unset)
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,
        sensitivity = 0, -- mouse sensitivity
        -- accel_profile = "", -- "flat", "adaptive" or "custom"; empty = libinput default
        numlock_by_default = true,
        left_handed = false,
        follow_mouse = 1,
        float_switch_override_focus = false,

        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            clickfinger_behavior = false,
            middle_button_emulation = false,
            tap_to_click = true, -- was "tap-to-click" in hyprlang (dashes -> underscores)
            drag_lock = false,
        },

        -- touchscreen
        touchdevice = {
            enabled = true,
        },

        -- tablets, see https://wiki.hypr.land/Configuring/Variables/#input
        tablet = {
            transform = 0,
            left_handed = false, -- was 0 in hyprlang (bool in Lua)
        },
    },

    -- NOTE: gestures.workspace_swipe / workspace_swipe_fingers / workspace_swipe_min_fingers
    -- were REMOVED in 0.55. To enable 3-finger workspace swipe use:
    --   hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    gestures = {
        workspace_swipe_distance = 500,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
        -- workspace_swipe_use_r = true, -- swipe right on last workspace creates a new one
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 2, -- 0 off, 1 on, 2 fullscreen only, 3 fullscreen with video/game
        mouse_move_enables_dpms = true,
        enable_swallow = false, -- was "off" in hyprlang (bool in Lua)
        swallow_regex = "^(kitty)$",
        focus_on_activate = false,
        initial_workspace_tracking = 0,
        middle_click_paste = false,
        enable_anr_dialog = true, -- Application not Responding (ANR)
        anr_missed_pings = 15,    -- ANR Threshold default 1 is too low
    },

    -- opengl {
    --   nvidia_anti_flicker = true
    -- }

    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        pass_mouse_when_bound = false,
    },

    -- Could help when scaling and not pixelating
    xwayland = {
        enabled = true,
        force_zero_scaling = true,
    },

    render = {
        direct_scanout = 0,
    },

    cursor = {
        sync_gsettings_theme = true,
        no_hardware_cursors = 2, -- change to 1 to disable hw cursors
        enable_hyprcursor = true,
        warp_on_change_workspace = 2,
        no_warps = true,
    },

    debug = {
        vfr = true, -- was misc.vfr before 0.55
    },
})
