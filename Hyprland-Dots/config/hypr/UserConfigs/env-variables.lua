-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Environment variables (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/ENVariables.conf
-- Must be loaded BEFORE any other hl.* call in hyprland.lua.
-- Wiki: https://wiki.hypr.land/Configuring/Environment-variables/
--
-- NOTE: NO $VAR expansion in Lua. Use os.getenv() for paths.

-- Toolkit Backend Variables
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")

-- Run SDL2 applications on Wayland.
-- Remove or set to "x11" if games that provide older versions of SDL cause compatibility issues
-- hl.env("SDL_VIDEODRIVER", "wayland")

-- xdg Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- QT Variables
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- hyprland-qt-support
hl.env("QT_QUICK_CONTROLS_STYLE", "org.hyprland.style")

-- xwayland apps scale fix (useful if you use monitor scaling).
-- Set same value if you use scaling in monitors.lua
-- 1 is 100% 1.5 is 150%
-- see https://wiki.hypr.land/Configuring/XWayland/
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")

-- Bibata-Modern-Classic cursor
-- NOTE! You must have the hyprcursor version to activate this.
-- https://wiki.hypr.land/Hypr-Ecosystem/hyprcursor/
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24") -- live machine value (repo default was 20)

-- XCursor fallback for XWayland/Qt/GTK apps that don't use hyprcursor
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")

-- firefox
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- electron >28 apps (may help)
-- https://www.electronjs.org/docs/latest/api/environment-variables
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- auto selects Wayland if possible, X11 otherwise

-- NVIDIA
-- From the Hyprland Wiki. Uncomment below for nvidia gpu detected setups.
-- https://wiki.hypr.land/Nvidia/#environment-variables

-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("NVD_BACKEND", "direct")
-- hl.env("GSK_RENDERER", "ngl")

-- additional ENV's for nvidia. Caution, activate with care
-- hl.env("GBM_BACKEND", "nvidia-drm")

-- hl.env("__GL_GSYNC_ALLOWED", "1") -- adaptive Vsync
-- hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
-- hl.env("__VK_LAYER_NV_optimus", "NVIDIA_only")
-- hl.env("WLR_DRM_NO_ATOMIC", "1")

-- FOR VM and POSSIBLY NVIDIA
-- LIBGL_ALWAYS_SOFTWARE software mesa rendering
-- hl.env("LIBGL_ALWAYS_SOFTWARE", "1") -- Warning. May cause hyprland to crash
-- hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

-- nvidia firefox (for hardware acceleration on FF)?
-- check this post https://github.com/elFarto/nvidia-vaapi-driver#configuration
-- hl.env("MOZ_DISABLE_RDD_SANDBOX", "1")
-- hl.env("EGL_PLATFORM", "wayland")

-- ===== Aquamarine Environment Variables (Hyprland > 0.45) =====
-- https://wiki.hypr.land/Configuring/Environment-variables/
-- hl.env("AQ_TRACE", "1") -- Enables more verbose logging.

-- Force Hyprland/Aquamarine to prefer the AMD iGPU as primary (the internal
-- panel eDP-1 is wired to it). NOTE: this does NOT put the NVIDIA GPU to
-- sleep in practice (confirmed 2026-08-04) - something outside Aquamarine's
-- device list (likely GLVND's default EGL/GLX vendor resolution) still keeps
-- it active. Tested stable across multiple logins; do not remove card1 from
-- this list again without a TTY safety net (doing so caused a login crash
-- loop on 2026-08-04 - see coredumpctl around 00:53 that day for the trace).
-- Use `prime-run <cmd>` to explicitly offload something to the NVIDIA GPU.
hl.env("AQ_DRM_DEVICES", "/dev/dri/card2:/dev/dri/card1")

-- Force EGL/GLX vendor to Mesa (AMD) so nothing in the session (Hyprland
-- itself, swaync, Chrome) defaults to the NVIDIA EGL ICD just because
-- 10_nvidia.json sorts before 50_mesa.json. Added 2026-08-05 to let the
-- NVIDIA dGPU actually reach RTD3 suspend (NVreg_DynamicPowerManagement=3
-- was already set at the kernel level, but fuser /dev/nvidia* showed
-- Hyprland/swaync/chrome holding it open regardless of AQ_DRM_DEVICES).
-- Revert: delete/comment these 3 lines and relogin.
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
hl.env("LIBVA_DRIVER_NAME", "radeonsi")

-- hl.env("AQ_MGPU_NO_EXPLICIT", "1") -- Disables explicit syncing on mgpu buffers
-- hl.env("AQ_NO_MODIFIERS", "1")     -- Disables modifiers for DRM buffers
-- hl.env("AQ_NO_KMS_REQUIREMENT", "1") -- allow starting on headless GPUs without KMS

-- ===== Hyprland Environment Variables =====
-- https://wiki.hypr.land/Configuring/Environment-variables/
-- hl.env("HYPRLAND_TRACE", "1")     -- Enables more verbose logging.
-- hl.env("HYPRLAND_NO_RT", "1")     -- Disables realtime priority setting by Hyprland.
-- hl.env("HYPRLAND_NO_SD_NOTIFY", "1") -- If systemd, disables the 'sd_notify' calls.
-- hl.env("HYPRLAND_NO_SD_VARS", "1")   -- Disables management of variables in systemd and dbus activation environments.
