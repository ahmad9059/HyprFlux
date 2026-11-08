#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Power menu (wlogout): square cards sized to the focused monitor and shown on it.
# Actions disabled by system policy or missing a resume path are
# left out, so every visible button does what it says.

scripts="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
wl_dir="${HYPRFLUX_WLOGOUT_DIR:-$HOME/.config/wlogout}"
layout="$wl_dir/layout"

# Pressing the shortcut again closes the menu.
if pgrep -x wlogout >/dev/null; then
  pkill -x wlogout
  exit 0
fi

# Fail closed if a filtered layout cannot be created. mktemp creates mode 0600.
suspend=false
hibernate=false
"$scripts/SleepAction.sh" suspend --check && suspend=true
"$scripts/SleepAction.sh" hibernate --check && hibernate=true
if [[ "$suspend" != true || "$hibernate" != true ]]; then
  filtered="$(mktemp "${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/hyprflux-wlogout-layout.XXXXXX")" || exit 1
  trap 'rm -f -- "$filtered"' EXIT
  jq -c --argjson suspend "$suspend" --argjson hibernate "$hibernate" \
    'select((.label != "suspend" or $suspend) and (.label != "hibernate" or $hibernate))' \
    "$layout" >"$filtered" 2>/dev/null || exit 1
  [[ -s "$filtered" ]] || exit 1
  layout="$filtered"
fi

buttons="$(jq -s 'length' "$layout" 2>/dev/null)"
[[ "$buttons" =~ ^[1-9][0-9]*$ ]] || buttons=6

args=(--protocol layer-shell --show-binds -l "$layout" -C "$wl_dir/style.css" -b "$buttons")

# Focused monitor: Hyprland id (wlogout's -P index), logical width and height.
# Rotated monitors swap width and height.
read -r mon_id width height < <(hyprctl -j monitors 2>/dev/null | jq -r '
  ([.[] | select(.focused == true)][0] // .[0] // empty) as $m
  | (if ($m.transform % 2) == 1 then [$m.height, $m.width] else [$m.width, $m.height] end) as [$w, $h]
  | "\($m.id) \($w / $m.scale | floor) \($h / $m.scale | floor)"' 2>/dev/null)

if [[ "${mon_id:-}" =~ ^[0-9]+$ && "${width:-}" =~ ^[0-9]+$ && "${height:-}" =~ ^[0-9]+$ ]]; then
  # Cards are squares: about a fifth of the screen height, never wider than
  # 90% of the screen across the whole row.
  card=$((height * 21 / 100))
  ((card < 160)) && card=160
  ((card > 300)) && card=300
  ((card > width * 9 / 10 / buttons)) && card=$((width * 9 / 10 / buttons))
  side=$(((width - buttons * card) / 2))
  vertical=$(((height - card) / 2))
  args+=(-P "$mon_id" -L "$side" -R "$side" -T "$vertical" -B "$vertical")
fi

wlogout "${args[@]}"
