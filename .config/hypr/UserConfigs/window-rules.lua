-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Window rules and layer rules (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/WindowRules.conf (96 rules + 3 layer rules, plus live rule 97)
-- Wiki: https://wiki.hypr.land/Configuring/Window-Rules/
--
-- ORDER MATTERS: rules evaluate top-to-bottom; for a given effect the LAST
-- matching rule wins. All rules here are named (like the old windowrule-N
-- blocks) — named rules evaluate before anonymous rules and take precedence.
--
-- Conversion notes:
--   match:class = ...            → match = { class = ... }
--   tag = +browser               → tag = "+browser"   (dynamic tag effect)
--   size = (w) (h)               → size = { "w", "h" } (expression strings)
--   center/float/tile/pin = on   → center/float/tile/pin = true
--   opacity = 0.9 0.7            → opacity = "0.9 0.7"
--   match:fullscreen = 1         → match = { fullscreen = true }

-- ============================= browser tags =============================
hl.window_rule({
    name = "windowrule-1",
    tag = "+browser",
    match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },
})

hl.window_rule({
    name = "windowrule-2",
    tag = "+browser",
    match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" },
})

hl.window_rule({
    name = "windowrule-3",
    tag = "+browser",
    match = { class = "^(chrome-.+-Default)$" }, -- Chrome PWAs
})

hl.window_rule({
    name = "windowrule-4",
    tag = "+browser",
    match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" },
})

hl.window_rule({
    name = "windowrule-5",
    tag = "+browser",
    match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" },
})

hl.window_rule({
    name = "windowrule-6",
    tag = "+browser",
    match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" },
})

hl.window_rule({
    name = "windowrule-7",
    tag = "+browser",
    match = { class = "^(zen-alpha|zen)$" },
})

-- ============================== notif tags ==============================
hl.window_rule({
    name = "windowrule-8",
    tag = "+notif",
    match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" },
})

-- ========================= HyprFlux settings tag ========================
hl.window_rule({
    name = "windowrule-9",
    tag = "+HyprFlux_Cheat",
    match = { title = "^(HyprFlux Quick Cheat Sheet)$" },
})

hl.window_rule({
    name = "windowrule-10",
    tag = "+HyprFlux_Settings",
    match = { title = "^(HyprFlux Settings)$" },
})

hl.window_rule({
    name = "windowrule-11",
    tag = "+HyprFlux-Settings",
    match = { class = "^(nwg-displays|nwg-look)$" },
})

-- ============================ terminal tags =============================
hl.window_rule({
    name = "windowrule-12",
    tag = "+terminal",
    match = { class = "^(Alacritty|kitty|kitty-dropterm)$" },
})

-- ============================== email tags ==============================
hl.window_rule({
    name = "windowrule-13",
    tag = "+email",
    match = { class = "^([Tt]hunderbird|org.gnome.Evolution)$" },
})

hl.window_rule({
    name = "windowrule-14",
    tag = "+email",
    match = { class = "^(eu.betterbird.Betterbird)$" },
})

-- ============================ project tags ==============================
hl.window_rule({
    name = "windowrule-15",
    tag = "+projects",
    match = { class = "^(codium|codium-url-handler|VSCodium)$" },
})

hl.window_rule({
    name = "windowrule-16",
    tag = "+projects",
    match = { class = "^(VSCode|code-url-handler)$" },
})

hl.window_rule({
    name = "windowrule-17",
    tag = "+projects",
    match = { class = "^(jetbrains-.+)$" }, -- JetBrains IDEs
})

-- =========================== screenshare tags ===========================
hl.window_rule({
    name = "windowrule-18",
    tag = "+screenshare",
    match = { class = "^(com.obsproject.Studio)$" },
})

-- ============================== IM tags =================================
hl.window_rule({
    name = "windowrule-19",
    tag = "+im",
    center = true,
    float = true,
    size = { "monitor_w*0.6", "monitor_h*0.7" },
    match = { class = "^([Ff]erdium)$" },
})

hl.window_rule({
    name = "windowrule-20",
    tag = "+im",
    match = { class = "^([Ww]hatsapp-for-linux)$" },
})

hl.window_rule({
    name = "windowrule-21",
    tag = "+im",
    match = { class = "^(ZapZap|com.rtosta.zapzap)$" },
})

hl.window_rule({
    name = "windowrule-22",
    tag = "+im",
    match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" },
})

hl.window_rule({
    name = "windowrule-23",
    tag = "+im",
    match = { class = "^(teams-for-linux)$" },
})

hl.window_rule({
    name = "windowrule-24",
    tag = "+im",
    match = { class = "^(im.riot.Riot|Element)$" }, -- Element Matrix client
})

-- ============================== game tags ===============================
hl.window_rule({
    name = "windowrule-25",
    tag = "+games",
    match = { class = "^(gamescope)$" },
})

hl.window_rule({
    name = "windowrule-26",
    tag = "+games",
    match = { class = "^(steam_app_\\d+)$" },
})

-- ============================ gamestore tags ============================
hl.window_rule({
    name = "windowrule-27",
    tag = "+gamestore",
    match = { class = "^([Ss]team)$" },
})

hl.window_rule({
    name = "windowrule-28",
    tag = "+gamestore",
    match = { title = "^([Ll]utris)$" },
})

hl.window_rule({
    name = "windowrule-29",
    tag = "+gamestore",
    match = { class = "^(com.heroicgameslauncher.hgl)$" },
})

-- ========================== file-manager tags ===========================
hl.window_rule({
    name = "windowrule-30",
    tag = "+file-manager",
    match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" },
})

hl.window_rule({
    name = "windowrule-31",
    tag = "+file-manager",
    match = { class = "^(app.drey.Warp)$" },
})

-- =========================== wallpaper tags =============================
hl.window_rule({
    name = "windowrule-32",
    tag = "+wallpaper",
    match = { class = "^([Ww]aytrogen)$" },
})

-- =========================== multimedia tags ============================
hl.window_rule({
    name = "windowrule-33",
    tag = "+multimedia",
    match = { class = "^([Aa]udacious)$" },
})

-- ======================== multimedia-video tags =========================
hl.window_rule({
    name = "windowrule-34",
    tag = "+multimedia_video",
    match = { class = "^([Mm]pv|vlc)$" },
})

-- ============================ settings tags =============================
hl.window_rule({
    name = "windowrule-35",
    tag = "+settings",
    center = true,
    match = { title = "^(ROG Control)$" },
})

hl.window_rule({
    name = "windowrule-36",
    tag = "+settings",
    match = { class = "^(wihotspot(-gui)?)$" }, -- wifi hotspot
})

hl.window_rule({
    name = "windowrule-37",
    tag = "+settings",
    match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" }, -- Disk usage analyzer
})

hl.window_rule({
    name = "windowrule-38",
    tag = "+settings",
    match = { class = "^(gnome-disks|wihotspot(-gui)?)$" },
})

hl.window_rule({
    name = "windowrule-39",
    tag = "+settings",
    match = { title = "(Kvantum Manager)" },
})

hl.window_rule({
    name = "windowrule-40",
    tag = "+settings",
    match = { class = "^(file-roller|org.gnome.FileRoller)$" }, -- archive manager
})

hl.window_rule({
    name = "windowrule-41",
    tag = "+settings",
    match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" },
})

hl.window_rule({
    name = "windowrule-42",
    tag = "+settings",
    center = true,
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
})

hl.window_rule({
    name = "windowrule-43",
    tag = "+settings",
    match = { class = "^(qt5ct|qt6ct|[Yy]ad)$" },
})

hl.window_rule({
    name = "windowrule-44",
    tag = "+settings",
    match = { class = "(xdg-desktop-portal-gtk)" },
})

hl.window_rule({
    name = "windowrule-45",
    tag = "+settings",
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
})

hl.window_rule({
    name = "windowrule-46",
    tag = "+settings",
    match = { class = "^([Rr]ofi)$" },
})

-- ============================ Custom rules ==============================
hl.window_rule({
    name = "windowrule-47",
    tile = true,
    match = { class = "^([Cc]hromium)$" },
})

hl.window_rule({
    name = "windowrule-48",
    size = { "monitor_w*0.25", "monitor_h*0.55" },
    float = true,
    match = { class = "^(com.network.manager)$" },
})

hl.window_rule({
    name = "windowrule-49",
    workspace = "special:nyx",
    match = { class = "^([Vv]esktop|[Dd]iscord|[Ss]potify)$" },
})

-- ============================= viewer tags ==============================
hl.window_rule({
    name = "windowrule-50",
    tag = "+viewer",
    match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" }, -- system monitor
})

hl.window_rule({
    name = "windowrule-51",
    tag = "+viewer",
    match = { class = "^(evince)$" }, -- document viewer
})

hl.window_rule({
    name = "windowrule-52",
    tag = "+viewer",
    match = { class = "^(eog|org.gnome.Loupe)$" }, -- image viewer
})

-- ====================== special override rules ==========================
hl.window_rule({
    name = "windowrule-53",
    no_blur = true,
    opacity = "1.0",
    match = { tag = "multimedia_video*" },
})

-- ============================= POSITION ================================
-- hl.window_rule({ match = { float = true }, center = true }) -- warning: floats even menus
hl.window_rule({
    name = "windowrule-54",
    center = true,
    float = true,
    size = { "monitor_w*0.65", "monitor_h*0.9" },
    match = { tag = "HyprFlux_Cheat*" },
})

hl.window_rule({
    name = "windowrule-55",
    center = true,
    float = true,
    match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" },
})

hl.window_rule({
    name = "windowrule-56",
    center = true,
    float = true,
    match = { tag = "HyprFlux-Settings*" },
})

hl.window_rule({
    name = "windowrule-57",
    center = true,
    match = { title = "^(Keybindings)$" },
})

hl.window_rule({
    name = "windowrule-58",
    center = true,
    size = { "monitor_w*0.6", "monitor_h*0.7" },
    match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
})

hl.window_rule({
    name = "windowrule-59",
    move = { "(monitor_w*0.61)", "(monitor_h*0.07)" },
    float = true,
    size = { "monitor_w*0.38", "monitor_h*0.38" },
    pin = true,
    keep_aspect_ratio = true,
    match = { title = "^(Picture-in-Picture)$" },
})

-- windowrule to avoid idle for fullscreen apps
-- hl.window_rule({ match = { class = ".*" }, idle_inhibit = "fullscreen" })
-- hl.window_rule({ match = { title = ".*" }, idle_inhibit = "fullscreen" })
hl.window_rule({
    name = "windowrule-60",
    idle_inhibit = "fullscreen",
    match = { fullscreen = true },
})

-- ====================== windowrule move to workspace ====================
hl.window_rule({
    name = "windowrule-61",
    workspace = "1",
    match = { tag = "projects*" },
})

hl.window_rule({
    name = "windowrule-62",
    workspace = "1",
    match = { tag = "email*" },
})

hl.window_rule({
    name = "windowrule-63",
    workspace = "2",
    match = { tag = "browser*" },
})

hl.window_rule({
    name = "windowrule-64",
    workspace = "3",
    match = { class = "^([Tt]hunar)$" },
})

hl.window_rule({
    name = "windowrule-65",
    workspace = "4",
    match = { tag = "im*" },
})

hl.window_rule({
    name = "windowrule-66",
    workspace = "5",
    match = { tag = "gamestore*" },
})

hl.window_rule({
    name = "windowrule-67",
    workspace = "8",
    no_blur = true,
    fullscreen = true,
    match = { tag = "games*" },
})

hl.window_rule({
    name = "windowrule-68",
    workspace = "1",
    match = { class = "^(kitty)$", title = "^(tmuxifier)$" },
})

hl.window_rule({
    name = "windowrule-69",
    workspace = "9",
    match = { class = "^(virt-viewer)$" },
})

hl.window_rule({
    name = "windowrule-70",
    workspace = "10",
    match = { class = "^([Oo]bsidian)$" },
})

-- ================== windowrule move to workspace (silent) ================
hl.window_rule({
    name = "windowrule-71",
    workspace = "4 silent",
    match = { tag = "screenshare*" },
})

hl.window_rule({
    name = "windowrule-72",
    workspace = "9 silent",
    match = { class = "^(virt-manager)$" },
})

hl.window_rule({
    name = "windowrule-73",
    workspace = "9 silent",
    match = { class = "^(.virt-manager-wrapped)$" },
})

hl.window_rule({
    name = "windowrule-74",
    workspace = "9 silent",
    match = { tag = "multimedia*" },
})

-- =============================== FLOAT ==================================
hl.window_rule({
    name = "windowrule-75",
    float = true,
    opacity = "0.9 0.7",
    size = { "monitor_w*0.7", "monitor_h*0.7" },
    match = { tag = "wallpaper*" },
})

hl.window_rule({
    name = "windowrule-76",
    float = true,
    opacity = "0.8 0.7",
    size = { "monitor_w*0.7", "monitor_h*0.7" },
    match = { tag = "settings*" },
})

hl.window_rule({
    name = "windowrule-77",
    float = true,
    match = { tag = "viewer*" },
})

hl.window_rule({
    name = "windowrule-78",
    float = true,
    match = { class = "([Zz]oom|onedriver|onedriver-launcher)$" },
})

hl.window_rule({
    name = "windowrule-79",
    float = true,
    match = { class = "(org.gnome.Calculator)", title = "(Calculator)" },
})

hl.window_rule({
    name = "windowrule-80",
    float = true,
    match = { class = "^(mpv|com.github.rafostar.Clapper)$" },
})

hl.window_rule({
    name = "windowrule-81",
    float = true,
    match = { class = "^([Qq]alculate-gtk)$" },
})

-- hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, float = true })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, float = true })
hl.window_rule({
    name = "windowrule-82",
    float = true,
    match = { class = "^(fdm|freedownloadmanager)$" },
})

hl.window_rule({
    name = "windowrule-83",
    float = true,
    match = { class = "^(proton-authenticator)$" },
})

hl.window_rule({
    name = "windowrule-84",
    float = true,
    match = { class = "^([Ww]indscribe)$" },
})

-- =============== float popups and dialogues ===============
hl.window_rule({
    name = "windowrule-85",
    float = true,
    center = true,
    match = { title = "^(Authentication Required)$" },
})

hl.window_rule({
    name = "windowrule-86",
    float = true,
    match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" },
})

hl.window_rule({
    name = "windowrule-87",
    float = true,
    match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:(Heroic Games Launcher)" },
})

hl.window_rule({
    name = "windowrule-88",
    float = true,
    match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" },
})

hl.window_rule({
    name = "windowrule-89",
    float = true,
    size = { "monitor_w*0.7", "monitor_h*0.6" },
    center = true,
    match = { title = "^(Add Folder to Workspace)$" },
})

hl.window_rule({
    name = "windowrule-90",
    float = true,
    size = { "monitor_w*0.7", "monitor_h*0.6" },
    center = true,
    match = { title = "^(Save As)$" },
})

hl.window_rule({
    name = "windowrule-91",
    float = true,
    size = { "monitor_w*0.7", "monitor_h*0.6" },
    match = { initial_title = "(Open Files)" },
})

hl.window_rule({
    name = "windowrule-92",
    float = true,
    center = true,
    size = { "monitor_w*0.16", "monitor_h*0.12" },
    match = { title = "^(SDDM Background)$" }, -- HyprFlux YAD for setting SDDM background
})

-- ============================== OPACITY =================================
-- hl.window_rule({ match = { tag = "browser*" },        opacity = "0.9 0.7" })
-- hl.window_rule({ match = { tag = "projects*" },       opacity = "0.9 0.8" })
-- hl.window_rule({ match = { tag = "im*" },             opacity = "0.94 0.86" })
-- hl.window_rule({ match = { tag = "multimedia*" },     opacity = "0.94 0.86" })
-- hl.window_rule({ match = { tag = "file-manager*" },   opacity = "0.9 0.8" })
hl.window_rule({
    name = "windowrule-93",
    opacity = "0.8 0.7",
    match = { tag = "terminal*" },
})

-- hl.window_rule({ match = { tag = "viewer*" }, opacity = "0.82 0.75" })
hl.window_rule({
    name = "windowrule-94",
    opacity = "0.8 0.7",
    match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" },
})

hl.window_rule({
    name = "windowrule-95",
    opacity = "0.9 0.8",
    match = { class = "^(deluge)$" },
})

hl.window_rule({
    name = "windowrule-96",
    opacity = "0.9 0.8",
    match = { class = "^(seahorse)$" }, -- gnome-keyring gui
})

-- live machine: Playwright MCP browser (Chrome for Testing) -> workspace 6
-- class alone is "chromium-browser" (would also match a real system Chromium),
-- so the title is also matched since only the playwright-launched browser
-- reports "... - Google Chrome for Testing" in its title.
hl.window_rule({
    name = "windowrule-97",
    workspace = "6 silent",
    match = { class = "^(chromium-browser)$", title = ".*Chrome for Testing.*" },
})

-- ============================= LAYER RULES ==============================
hl.layer_rule({
    name = "layerrule-1",
    blur = true,
    ignore_alpha = 0,
    match = { namespace = "rofi" },
})

hl.layer_rule({
    name = "layerrule-2",
    blur = true,
    ignore_alpha = 0,
    match = { namespace = "notifications" },
})

hl.layer_rule({
    name = "layerrule-3",
    blur = true,
    ignore_alpha = 0.5,
    match = { namespace = "quickshell:overview" },
})

-- hl.layer_rule({ match = { namespace = "notif*" }, ignore_alpha = 0.5 })
-- hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0 }) -- ignorezero
-- hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
-- hl.layer_rule({ match = { namespace = "overview" }, ignore_alpha = 0 })
-- hl.layer_rule({ match = { namespace = "overview" }, blur = true })
