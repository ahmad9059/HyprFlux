-- HyprFlux — https://github.com/ahmad9059/HyprFlux
-- Laptop keybinds & devices (Lua module, Hyprland >= 0.55)
--
-- Replaces: UserConfigs/Laptops.conf (13 binds + device block)
-- These configs are mostly for laptops. This is an addendum to configs/keybinds.lua.

local Home = os.getenv("HOME")
local mainMod = "SUPER"
local scriptsDir = Home .. "/.config/hypr/scripts"
local UserConfigs = Home .. "/.config/hypr/UserConfigs"

-- ASUS ROG specifics are guarded: on non-ASUS machines the device name
-- does not exist (hl.device is a documented no-op) and the tools below are
-- absent, so these binds simply never fire. Safe on any hardware.
local Touchpad_Device = "asue1209:00-04f3:319f-touchpad" -- maintainer's ROG

hl.device({ name = Touchpad_Device, enabled = true })

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --dec"), { repeating = true }) -- keyboard brightness down
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/BrightnessKbd.sh --inc"), { repeating = true }) -- keyboard brightness up

-- ASUS-only keys (XF86Launch* only exist on ASUS keyboards / asusctl)
if os.execute("command -v rog-control-center >/dev/null 2>&1") then
    hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center"), { description = "ASUS Armory crate button" })
end
if os.execute("command -v asusctl >/dev/null 2>&1") then
    hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"), { description = "FN+F4: Switch keyboard RGB profile" })
    hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"), { description = "FN+F5: fan profiles (Quiet, Balance, Performance)" })
end
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --dec"), { repeating = true }) -- monitor brightness down
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scriptsDir .. "/Brightness.sh --inc"), { repeating = true }) -- monitor brightness up
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd(scriptsDir .. "/TouchPad.sh"), { description = "Toggle touchpad" })

-- Screenshot keybindings using F6 (no PrintSrc button)
hl.bind(mainMod .. " + F6",        hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"), { description = "Screenshot" })
hl.bind(mainMod .. " + SHIFT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"), { description = "Screenshot (area)" })
hl.bind(mainMod .. " + CTRL + F6",  hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"), { description = "Screenshot (5s delay)" })
hl.bind(mainMod .. " + ALT + F6",   hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"), { description = "Screenshot (10s delay)" })
hl.bind("ALT + F6", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"), { description = "Screenshot (active window)" })

-- Below are useful when connecting the laptop to an external display.
-- Suggest editing for your laptop display.
-- From the WIKI: disable the laptop monitor when the lid is closed.
-- consult https://wiki.hypr.land/Configuring/Binds/#switches
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1, preferred, auto, 1\""), { locked = true })
-- hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1, disable\""), { locked = true })

-- WARNING! Using this method has some caveats!! USE THIS PART WITH SOME CAUTION!
-- CONS: you need to set up your wallpaper (SUPER W) and choose wallpaper.
-- CAVEATS! Sometimes the Main Laptop Monitor DOES NOT have display and you need
-- to re-connect your external monitor.
-- One workaround: before shutting down the laptop, MAKE SURE your laptop lid is OPEN!
-- Make sure to comment (put # on the both switch binds above)
-- NOTE: the laptop display config is generated into LaptopDisplay.lua
-- This part is to be used if you do NOT want your main laptop monitor to wake
-- up during e.g. wallpaper changes.
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("printf 'hl.monitor({ output = \\\"eDP-1\\\", mode = \\\"preferred\\\", position = \\\"auto\\\", scale = 1 })\\n' > " .. UserConfigs .. "/LaptopDisplay.lua"), { locked = true })
-- hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("printf 'hl.monitor({ output = \\\"eDP-1\\\", disabled = true })\\n' > " .. UserConfigs .. "/LaptopDisplay.lua"), { locked = true })
-- for laptop-lid action (to erase the last entry):
-- hl.on("hyprland.start", function() hl.exec_cmd("printf 'hl.monitor({ output = \\\"eDP-1\\\", mode = \\\"preferred\\\", position = \\\"auto\\\", scale = 1 })\\n' > " .. UserConfigs .. "/LaptopDisplay.lua") end)
