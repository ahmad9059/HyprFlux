-- Side-effect-free behavioral checks. This supplements, not replaces, Hyprland.
local root, layout_script = arg[1], arg[2]
package.path = root .. "/.config/hypr/?.lua;" .. package.path
local binds, dispatched, rules, commands = {}, {}, {}, {}
local active, special
local function factory(kind)
    return function(options) return { kind = kind, options = options } end
end
local function namespace(prefix)
    return setmetatable({}, { __index = function(_, key) return factory(prefix .. key) end })
end
hl = {
    dsp = namespace(""),
    bind = function(key, action, options)
        local parts = {}
        for part in key:gmatch("[^+]+") do
            parts[#parts + 1] = part:match("^%s*(.-)%s*$"):upper()
        end
        local normalized = table.concat(parts, "+")
        assert(not binds[normalized], "Duplicate bind: " .. normalized)
        binds[normalized] = { action = action, options = options }
    end,
    get_active_workspace = function() return active end,
    get_active_special_workspace = function() return special end,
    dispatch = function(action) dispatched[#dispatched + 1] = action end,
    workspace_rule = function(rule) rules[#rules + 1] = rule end,
    exec_cmd = function(command) commands[#commands + 1] = command end,
    device = function() end,
}
hl.dsp.window = namespace("window.")
hl.dsp.workspace = namespace("workspace.")
-- Availability checks must not execute external tools during a unit test.
os.execute = function() return true end
require("configs.keybinds")
require("UserConfigs.user-keybinds")
require("UserConfigs.laptops")

for i = 1, 10 do
    local move = binds["SUPER+CTRL+CODE:" .. (9 + i)].action
    assert(move.kind == "window.move")
    assert(move.options.workspace == i and move.options.follow == false)
end
for _, key in ipairs({"BRACKETLEFT", "BRACKETRIGHT"}) do
    local move = binds["SUPER+CTRL+" .. key].action
    assert(move.options.follow == false)
    assert(not move.options.workspace:find("silent", 1, true))
end
assert(not binds["CODE:164"], "evdev code is not an XKB keycode")
assert(not binds["CODE:172"], "would duplicate XF86AudioPlay")
assert(binds["XF86AUDIOPLAY"] and binds["XF86AUDIOPAUSE"])
assert(binds["SUPER+SHIFT+P"].action.options == "hyprpicker -a")
assert(binds["SUPER+ALT+K"].action.options == "kdenlive")
assert(binds["SUPER+ALT+O"].action.options:find("obsidian", 1, true))
assert(binds["SUPER+CTRL+W"].action.options:find("WallpaperEffects.sh", 1, true))
assert(binds["SUPER+SHIFT+W"].action.options:find("WallpaperSelect.sh", 1, true))

local guards = {
    ["SUPER+K"] = {"master", "cycleprev"},
    ["SUPER+O"] = {"dwindle", "togglesplit"},
    ["SUPER+SHIFT+I"] = {"dwindle", "rotatesplit"},
}
for key, expected in pairs(guards) do
    local callback = binds[key].action
    for _, layout in ipairs({"master", "dwindle", "scrolling"}) do
        active, special = {tiled_layout = layout}, nil
        dispatched = {}
        callback()
        assert(#dispatched == (layout == expected[1] and 1 or 0), key)
        if #dispatched > 0 then assert(dispatched[1].options == expected[2]) end
    end
    active, special = nil, nil
    callback() -- No active workspace must be safe.
    active = {tiled_layout = "scrolling"}
    special = {tiled_layout = expected[1]}
    dispatched = {}
    callback()
    assert(#dispatched == 1, "Special workspace must take priority: " .. key)
end

local cycle = assert(loadfile(layout_script))
for _, state in ipairs({
    {name = "1", tiled_layout = "dwindle", expected = "master"},
    {name = "coding", tiled_layout = "master", expected = "scrolling"},
    {name = "2", tiled_layout = "scrolling", expected = "dwindle"},
    {name = "3", tiled_layout = "plugin-layout", expected = "dwindle"},
}) do
    active, special, rules = state, nil, {}
    cycle()
    assert(#rules == 1 and rules[1].workspace == "name:" .. state.name)
    assert(rules[1].layout == state.expected)
end
active = {name = "1", tiled_layout = "master"}
special = {name = "special:nyx", special = true, tiled_layout = "scrolling"}
rules = {}
cycle()
assert(#rules == 1 and rules[1].workspace == "special:nyx")
assert(rules[1].layout == "dwindle")
active, special, rules = nil, nil, {}
cycle()
assert(#rules == 0)
print("Binding and workspace callback checks passed")
