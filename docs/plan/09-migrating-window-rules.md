# 09 — Migrating Window and Layer Rules (`hl.window_rule`)

HyprFlux's `UserConfigs/WindowRules.conf` is the biggest file in the config (13 KB, 96
`windowrule` blocks + 3 `layerrule` blocks). Rules are **order-sensitive** — preserve order.

## 9.1 Semantics recap

- Props (the `match` table) decide *whether* the rule applies; effects decide *what* applies.
- **All** props must match (AND).
- Rules evaluate top-to-bottom; for a given effect, the **last matching rule wins**.
- **Named rules evaluate first, then anonymous**; named rules take precedence. Name them if you
  need handle-based toggling, but be aware they outrank anonymous rules.
- Static effects (float, workspace, move, size, pin…) run once at window open. Dynamic effects
  (opacity, border_color, no_blur…) re-run when window properties change.

## 9.2 Converting the HyprFlux block syntax

Your `WindowRules.conf` already uses the modern hyprlang block form (Hyprland ≥ 0.48). Each
block converts nearly mechanically:

```lua
-- hyprlang block:
-- windowrule-1 {
--   match = class:^(firefox|chrome)$
--   workspace = 2
-- }

hl.window_rule({ match = { class = "^(firefox|chrome)$" }, workspace = "2" })
```

```lua
-- windowrule-2 {
--   match = class:^(thunar)$
--   workspace = 3
--   float = true
--   center = true
-- }
hl.window_rule({ match = { class = "^(thunar)$" }, workspace = "3", float = true, center = true })
```

### Field mapping for the block form

| hyprlang block key | Lua |
|---|---|
| `match = class:...` / `title:...` | `match = { class = "..." }` / `{ title = "..." }` |
| `workspace = N` | `workspace = "N"` (or `"N silent"`) |
| `float = true` | `float = true` |
| `center = true` | `center = true` |
| `size = W H` | `size = { W, H }` |
| `move = X Y` | `move = { X, Y }` |
| `opacity = 0.8 0.7` | `opacity = "0.8 0.7"` |
| `border_size = N` | `border_size = N` |
| `no_blur = true` | `no_blur = true` |
| `no_shadow = true` | `no_shadow = true` |
| `no_anim = true` | `no_anim = true` |
| `pin = true` | `pin = true` |
| `suppress_event = ...` | `suppress_event = "..."` |
| `idle_inhibit = ...` | `idle_inhibit = "..."` |
| `no_initial_focus = true` | `no_initial_focus = true` |

> If any rule in your file is still `windowrulev2 = ...` (legacy one-line), `WindowRules-old.conf`
> is 100% legacy — both map via doc 05 §5.5.

## 9.3 Full `match` prop set

```lua
match = {
    class = "regex",            title = "regex",
    initial_class = "regex",    initial_title = "regex",
    tag = "name",               xdg_tag = "regex",
    xwayland = true,            float = true,
    fullscreen = true,          pin = true,
    focus = true,               group = true,
    modal = true,
    fullscreen_state_client = 0,    fullscreen_state_internal = 0,
    workspace = "2",            content = "video",
}
```

Regexes are **RE2**; negate with `"negative:..."` prefix.

## 9.4 Static vs dynamic — and the HyprFlux gotcha

HyprFlux has rules that float/focus windows *after* title changes (e.g. browser downloads popups,
chromium "Chrome for Testing"). Those are dynamic in hyprlang only if they used dynamic effects;
**static effects (float, workspace, size, move) cannot react to later title changes** — the old
behavior of re-evaluating on title change is gone for static effects. Replace with event handlers:

```lua
hl.on("window.title", function(w)
    if w.title:match(".*Chrome for Testing.*") and w.class == "chromium-browser" then
        hl.dispatch(hl.dsp.window.move({ workspace = "6 silent", window = w.address }))
    end
end)
```

## 9.5 Layer rules (HyprFlux has 3)

```lua
-- layerrule = blur, rofi
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.5 })

-- layerrule = blur, notifications
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })

-- layerrule = noanim, quickshell  (overview)
hl.layer_rule({ match = { namespace = "quickshell" }, no_anim = true })
```

Layer effects: `no_anim`, `blur`, `blur_popups`, `ignore_alpha`, `dim_around`, `xray`,
`animation`, `order`, `above_lock`, `no_screen_share`.

## 9.6 Named rules → runtime handles

HyprFlux's toggle scripts (blur toggle, gamemode, layout change) can replace
"hyprctl keyword" hacks with handles:

```lua
local noBlurForKitty = hl.window_rule({ name = "no-blur-kitty", match = { class = "kitty" }, no_blur = true })

hl.bind("SUPER + SHIFT + B", function()
    noBlurForKitty:set_enabled(not noBlurForKitty:is_enabled())
end)
```

## 9.7 `exec_cmd` with rules (dispatcher form)

```lua
-- old:  bind = SUPER, E, exec, kitty
-- new (apply a rule to the spawned window):
hl.bind("SUPER + E", hl.dsp.exec_cmd("kitty", { float = true, move = { 0, 0 } }))
```

## 9.8 Opacity math

Opacities **multiply** across matching rules (`active_opacity 0.5` × `opacity 0.5` = 0.25).
Use the ` override` suffix for absolutes: `"1.0 override 0.5 override 0.8 override"`.

Next: [10-migrating-autostart-and-environment.md](10-migrating-autostart-and-environment.md)
