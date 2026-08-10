# 02 — Lua Syntax Crash Course (for Hyprland configs)

You do not need to "learn Lua" to migrate. You need ~20 minutes of concepts. This document covers
exactly the subset used in `hyprland.lua` and the `hl.*` API. Test snippets live in the REPL:
`hyprctl repl` (0.56+) — or just edit `hyprland.lua` and watch it reload.

---

## 2.1 Comments

```lua
-- single line comment
--[[ multi
     line ]]--
```

## 2.2 Values & types

```lua
local n    = 10        -- number (integers and floats are the same type)
local f    = 1.5       -- float
local s    = "string"  -- string (double or single quotes)
local b    = true      -- boolean
local nil_ = nil       -- the absence of a value
```

## 2.3 Tables — the only data structure

Tables are `{}` with either array or key/value entries (or both):

```lua
local arr = { "a", "b", "c" }        -- array: 1-based indexing!
print(arr[1])                        -- "a"

local map = { name = "eDP-1", mode = "2560x1440" }   -- key/value
print(map.name)                      -- "eDP-1"
print(map["mode"])                   -- "2560x1440" (same thing)
```

**The entire `hl.*` API is table-based.** The Hyprland config is literally just Lua tables:

```lua
hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1.0 })
```

Note: when a Hyprland field needs an explicit nil-default value (e.g. unset a color), you can
write `value = nil` — the field is then treated as unset by `hl.config()`.

## 2.4 Local variables & concatenation

Replaces hyprlang's `$VAR`:

```lua
local mainMod  = "SUPER"
local term     = "kitty"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(term))
-- "SUPER + RETURN"
```

- `..` concatenates strings; numbers must be converted: `"workspace " .. tostring(3)`.
- There is **no** `$VAR` substitution. `hl.env("FOO", "$HOME/x")` writes a literal `$HOME` folder
  (a real user destroyed `~` with `rm -rf "$HOME"` after this). Use `os.getenv("HOME") .. "/x"`.

## 2.5 Functions & closures

```lua
local function greet(name)
    return "hello " .. name
end

-- anonymous function (used constantly as keybind bodies)
hl.bind("SUPER + SHIFT + G", function()
    hl.config({ general = { gaps_in = 0 } })
end)
```

A **closure** captures surrounding locals — the idiomatic way to parameterize binds:

```lua
local function gotoWorkspace(i)
    return function()
        hl.dispatch(hl.dsp.focus({ workspace = i }))
    end
end
hl.bind("SUPER + 1", gotoWorkspace(1))
hl.bind("SUPER + 2", gotoWorkspace(2))
```

## 2.6 Loops — the killer feature for HyprFlux

hyprlang needed one `bind` line per key. Lua generates them:

```lua
-- SUPER + 1..0 → workspaces 1..10 (keycode-style, like HyprFlux's Keybinds.conf)
for i = 1, 10 do
    local key = (i % 10) .. ""   -- 1 2 3 ... 9 0
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    hl.bind("SUPER + CTRL + " .. key, hl.dsp.window.move({ workspace = "special:" .. tostring(i) }))
end
```

That is **30 binds in 8 lines** (see doc 07 for the full HyprFlux loop table).

## 2.7 Conditionals

```lua
local gaps = hl.get_config("general.gaps_in")
if gaps.top == 3 then
    hl.config({ general = { gaps_in = 0 } })
else
    hl.config({ general = { gaps_in = 3 } })
end
```

- Only `false` and `nil` are falsy. `0` and `""` are **truthy** — a classic Lua trap.
- `if` / `elseif` / `else` / `end`.

## 2.8 Error handling — `pcall`

`require()` of a missing module **kills** your config unless wrapped:

```lua
local ok, err = pcall(require, "UserConfigs.monitors")   -- optional include
if not ok then
    print("monitors module failed to load: " .. tostring(err))
end
```

## 2.9 Accessing the environment — `os.getenv`

```lua
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/ssh-agent.socket")
```

## 2.10 String methods

```lua
string.match("kitty", "kitty")       -- regex-ish matching (RE2, see doc 09)
("some.title"):match(".*%.[tT]itle") -- colon syntax
```

## 2.11 What NOT to do (compositor constraints)

```lua
-- ❌ blocks the compositor event loop → freezes your entire desktop
hl.bind("SUPER + X", function()
    local f = io.popen("wl-paste")     -- no
    os.execute("sleep 1")              -- no
    -- any network I/O                   -- no
end)

-- ✅ spawn async or defer
hl.bind("SUPER + X", hl.dsp.exec_cmd("my-script.sh"))
hl.timer(function() hl.dispatch(hl.dsp.dpms({ action = "disable" })) end, { timeout = 500, type = "oneshot" })
```

The Lua stdlib is fully loaded — your config can run arbitrary code, so only source files you
trust.

## 2.12 Common syntactic differences vs hyprlang, at a glance

| hyprlang | Lua |
|---|---|
| `$VAR = value` | `local VAR = value` |
| `general { gaps_in = 2 }` | `hl.config({ general = { gaps_in = 2 } })` |
| `bind = SUPER, Q, exec, kitty` | `hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"))` |
| `monitor = eDP-1, 2560x1440@165, 0x0, 1` | `hl.monitor({ output = "eDP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })` |
| `windowrulev2 = float, class:(kitty)` | `hl.window_rule({ match = { class = "kitty" }, float = true })` |
| `exec-once = waybar` | `hl.on("hyprland.start", function() hl.exec_cmd("waybar") end)` |
| `env = GDK_BACKEND,wayland` | `hl.env("GDK_BACKEND", "wayland")` |
| `source = path` | `require("path")` |
| `animation = name, 1, 5, bezier, style` | `hl.animation({ leaf = "name", enabled = true, speed = 5, bezier = "bezier", style = "style" })` |
| `bezier = name, x1, y1, x2, y2` | `hl.curve("name", { type = "bezier", points = { {x1, y1}, {x2, y2} } })` |

Full mapping: see [05-hyprlang-to-lua-mapping.md](05-hyprlang-to-lua-mapping.md).

Next: [03-config-loading-and-file-structure.md](03-config-loading-and-file-structure.md)
