-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Default Keybinds (Lua module, Hyprland >= 0.55)
--
-- Replaces: configs/Keybinds.conf (93 binds)
-- Wiki: https://wiki.hypr.land/Configuring/Binds/
--
-- Flag translation: bindel -> { locked = true, repeating = true } | bindl -> { locked = true }
--                  binde -> { repeating = true } | bindm -> { mouse = true }

local Home = os.getenv("HOME")
local mainMod = "SUPER"
local scriptsDir = Home .. "/.config/hypr/scripts"
local UserConfigs = Home .. "/.config/hypr/UserConfigs"
local UserScripts = Home .. "/.config/hypr/UserScripts"

-- Exit / lock / power / notifications
hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "Exit Hyprland" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close active window (not kill)" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh"), { description = "Kill active process" })
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh"), { description = "Screen lock" })
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"), { description = "Power menu" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"), { description = "swayNC notification panel" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(scriptsDir .. "/HyprFlux_Quick_Settings.sh"), { description = "HyprFlux Quick Settings Menu" })

-- Master Layout
hl.bind(mainMod .. " + CTRL + D", hl.dsp.layout("removemaster"))
hl.bind(mainMod .. " + I", hl.dsp.layout("addmaster"))
hl.bind(mainMod .. " + J", hl.dsp.layout("cyclenext"))
hl.bind(mainMod .. " + K", hl.dsp.layout("cycleprev"))
hl.bind(mainMod .. " + CTRL + RETURN", hl.dsp.layout("swapwithmaster"))

-- Dwindle Layout
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("rotatesplit")) -- only works on dwindle layout
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo({ action = "toggle" })) -- dwindle

-- Works on either layout (Master or Dwindle)
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl dispatch splitratio 0.3"))

-- group
-- hl.bind(mainMod .. " + G", ...)                       -- togglegroup
-- hl.bind(mainMod .. " + CTRL + tab", ...)              -- changegroupactive

-- Cycle windows; if floating, bring to top
hl.bind(mainMod .. " + J", hl.dsp.window.cycle_next({ next = true })) -- kept alongside layoutmsg cyclenext (original config had both)
-- hl.bind("ALT + tab", ...) -- bringactivetotop

-- Special Keys / Hot Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"), { locked = true, repeating = true }) -- volume up
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"), { locked = true, repeating = true }) -- volume down
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"), { locked = true }) -- mic mute
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"), { locked = true }) -- mute
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true }) -- sleep button
hl.bind("XF86Rfkill", hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"), { locked = true }) -- Airplane mode

-- media controls using keyboards
-- NOTE: XF86AudioPlayPause is not a valid keysym in the Lua API (it was
-- accepted by hyprlang) — bound via keycode 164 (KEY_PLAYPAUSE) instead.
hl.bind("code:164", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"), { locked = true })

-- Screenshot keybindings NOTE: You may need to press Fn key as well
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"), { description = "Screenshot" })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"), { description = "Screenshot (area)" })
hl.bind(mainMod .. " + CTRL + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"), { description = "Screenshot (5s delay)" })
hl.bind(mainMod .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"), { description = "Screenshot (10s delay)" })
hl.bind("ALT + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "Screenshot (active window)" })

-- screenshot with swappy (another screenshot tool)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --swappy"), { description = "Screenshot (swappy)" })

-- Resize windows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Move windows
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "d" }))

-- Swap windows
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "d" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

-- Workspaces related
hl.bind(mainMod .. " + tab",        hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + tab", hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace
-- hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }))
-- hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special(""))
hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special("nyx"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special:nyx" }))

-- The following mappings use key codes to better support various keyboard layouts
-- 1 is code:10, 2 is code:11, etc
-- Switch workspaces / move windows / move silently with mainMod + [0-9]
for i = 1, 10 do
    local code = 9 + i -- code:10 = key 1 ... code:19 = key 0
    local key = "code:" .. tostring(code)
    hl.bind(mainMod .. " + " .. key,          hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,  hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. key,   hl.dsp.window.move({ workspace = tostring(i) .. " silent" }))
end

hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }))   -- brackets [
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }))   -- brackets ]
hl.bind(mainMod .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1 silent" }))
hl.bind(mainMod .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1 silent" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + period",     hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + comma",      hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window (LMB drag)" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window (RMB drag)" })
