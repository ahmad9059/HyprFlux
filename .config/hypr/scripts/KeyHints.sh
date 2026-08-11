#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Quick cheat sheet — generated LIVE from the compositor binds
# (never drifts from the actual config; only binds with descriptions show)

# GDK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

# Kill rofi/yad if running
if pidof rofi >/dev/null; then pkill rofi; fi
if pidof yad >/dev/null; then pkill yad; fi

# Format live binds as "MODS + KEY\tDESCRIPTION"
keybinds=$(hyprctl binds -j 2>/dev/null | python3 -c '
import json, sys
MODS = {1: "SHIFT", 2: "CAPS", 4: "CTRL", 8: "ALT", 16: "MOD2", 32: "MOD3", 64: "SUPER", 128: "MOD5", 256: "NUM"}
try:
    binds = json.load(sys.stdin)
except Exception:
    sys.exit(0)
rows = []
for b in binds:
    modmask = b.get("modmask") or 0
    mods = [name for bit, name in sorted(MODS.items()) if modmask & bit]
    key = b.get("key") or ("code:" + str(b.get("keycode")))
    combo = " + ".join(mods + [key])
    desc = (b.get("description") or "").strip()
    if desc:
        rows.append(f"{combo}\t{desc}")
print("\n".join(rows))
')

if [[ -z "$keybinds" ]]; then
  echo "no keybinds found."
  exit 1
fi

# Launch yad with the live keybinds
GDK_BACKEND=$BACKEND yad \
  --center \
  --title="Hyprland Quick Cheat Sheet" \
  --no-buttons \
  --list \
  --column="Key:" \
  --column="Description:" \
  --timeout-indicator=bottom \
  $keybinds
