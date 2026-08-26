#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# searchable enabled keybinds using rofi
# (Hyprland >= 0.55: reads live binds from the compositor instead of parsing .conf)

# kill yad to not interfere with this binds
pkill yad || true

# check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

# format live binds from hyprctl as "MODS + KEY\tDESCRIPTION [flags]"
keybinds=$(hyprctl binds -j 2>/dev/null | python3 -c '
import json, sys
MODS = {1: "SHIFT", 2: "CAPS", 4: "CTRL", 8: "ALT", 16: "MOD2", 32: "MOD3", 64: "SUPER", 128: "MOD5", 256: "NUM"}
try:
    binds = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for b in binds:
    modmask = b.get("modmask") or 0
    mods = [name for bit, name in sorted(MODS.items()) if modmask & bit]
    key = b.get("key") or ("code:" + str(b.get("keycode")))
    combo = " + ".join(mods + [key])
    desc = (b.get("description") or "").strip()
    if not desc:
        desc = (b.get("dispatcher") or "") + " " + (b.get("arg") or "").strip()
    flags = []
    if b.get("locked"):    flags.append("[lock]")
    if b.get("repeat"):    flags.append("[repeat]")
    if b.get("release"):   flags.append("[release]")
    if b.get("mouse"):     flags.append("[mouse]")
    print(f"{combo}\t{desc} {" ".join(flags)}".rstrip())
')

# check for any keybinds to display
if [[ -z "$keybinds" ]]; then
  echo "no keybinds found."
  exit 1
fi

# use rofi to display the keybinds
echo "$keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
