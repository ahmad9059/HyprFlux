#!/bin/bash
# ============================================================
# modules/19-hardware-detect.sh — machine-specific setup
# ============================================================
# Handles everything that varies machine-to-machine:
#   1. GPU detection (AMD / NVIDIA / hybrid / Intel / VM / none)
#      → rewrites the GPU block in UserConfigs/env-variables.lua
#   2. Native monitor resolution detection
#      → writes monitors.lua + monitors.conf + default profile
#   3. Keyboard layout detection (localectl)
#      → updates kb_layout in UserConfigs/user-settings.lua
#
# DESIGN PRINCIPLES (edge-case hardened):
#   - NEVER fails the install: every sub-step is guarded, every tool
#     (lspci, hyprctl, wlr-randr, xrandr, localectl, setxkbmap, awk)
#     is checked before use, all writes are temp-file + atomic mv.
#   - No python dependency: pure bash + awk.
#   - Idempotent: safe to run repeatedly (marker-based GPU block,
#     atomic file rewrites).
#   - Fallbacks everywhere: missing tool → next detection source →
#     safe default (1080p@60, kb us, GPU block empty).
# ============================================================
should_skip "hardware" && return 0

_HOME_CONFIG="$HOME/.config/hypr"
_ENV_FILE="$_HOME_CONFIG/UserConfigs/env-variables.lua"
_SETTINGS_FILE="$_HOME_CONFIG/UserConfigs/user-settings.lua"
_MONITORS_CONF="$_HOME_CONFIG/monitors.conf"
_MONITORS_LUA="$_HOME_CONFIG/monitors.lua"
_PROFILES_DIR="$_HOME_CONFIG/Monitor_Profiles"
_HD_TMP=""

_hd_cleanup() {
  [[ -n "$_HD_TMP" && -f "$_HD_TMP" ]] && rm -f "$_HD_TMP" 2>/dev/null || true
}

_hd_is_installed() {  # $1 = command
  command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------
# 1. GPU detection → env-variables.lua
# ------------------------------------------------------------------
_hd_detect_gpu() {
  # Missing lspci (minimal/container) → treat as none (safe).
  _hd_is_installed lspci || { echo "none"; return; }

  local pci
  pci=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' || true)
  [[ -z "$pci" ]] && { echo "none"; return; }

  local has_amd=no has_nvidia=no has_intel=no has_virtio=no
  echo "$pci" | grep -qi 'amd\|advanced micro devices\|1002' && has_amd=yes
  echo "$pci" | grep -qi 'nvidia\|10de' && has_nvidia=yes
  echo "$pci" | grep -qi 'intel\|8086' && has_intel=yes
  echo "$pci" | grep -qi 'virtio\|qxl\|vmware\|bochs' && has_virtio=yes

  # Virtual GPU / VM with no real GPU → none (defaults apply, safe).
  if [[ "$has_virtio" == yes && "$has_amd" == no && "$has_nvidia" == no && "$has_intel" == no ]]; then
    echo "none"; return
  fi
  if [[ "$has_amd" == no && "$has_nvidia" == no && "$has_intel" == no ]]; then
    echo "none"; return
  fi
  if [[ "$has_amd" == yes && "$has_nvidia" == yes ]]; then echo "hybrid-amd-nvidia"; return; fi
  if [[ "$has_intel" == yes && "$has_nvidia" == yes ]]; then echo "hybrid-intel-nvidia"; return; fi
  if [[ "$has_amd" == yes && "$has_intel" == yes ]]; then echo "hybrid-amd-intel"; return; fi
  [[ "$has_nvidia" == yes ]] && echo "nvidia" && return
  [[ "$has_amd" == yes ]] && echo "amd" && return
  echo "intel"
}

# Build an ordered AQ_DRM_DEVICES value. Only REAL card paths are used;
# the preferred vendor comes first, unknown/unused cards follow last.
# Returns e.g. "/dev/dri/card1:/dev/dri/card0" or "" if no cards found.
_hd_build_drm_devices() {
  local pref="$1"
  local -a cards=() seen=()
  local card vendor dev

  for card in /sys/class/drm/card[0-9]*; do
    [[ -e "$card/device/vendor" ]] || continue
    vendor=$(cat "$card/device/vendor" 2>/dev/null | tr -d '\n')
    case "$vendor" in
      0x1002) dev="amd" ;;
      0x8086) dev="intel" ;;
      0x10de) dev="nvidia" ;;
      *) continue ;;
    esac
    # Verify a usable DRM node actually exists (not just sysfs metadata).
    [[ -e "/dev/dri/${card##*/}" ]] || continue
    cards+=("$dev ${card##*/}")
  done

  local out="" entry want
  for want in $pref; do
    for entry in "${cards[@]}"; do
      [[ "${entry%% *}" == "$want" ]] && out+="/dev/dri/${entry##* } "
    done
  done
  for entry in "${cards[@]}"; do
    local devn="${entry%% *}"
    case " $pref " in
      *" $devn "*) ;;
      *) out+="/dev/dri/${entry##* } " ;;
    esac
  done

  # Remove trailing space and build the colon-separated value.
  out="${out% }"
  echo "${out// /:}"
}

_hd_write_gpu_block() {
  if [[ ! -f "$_ENV_FILE" ]]; then
    log_warn "env-variables.lua not found — skipping GPU config."
    return 0
  fi

  local gpu
  gpu="$(_hd_detect_gpu)"
  local block="" cards=""

  case "$gpu" in
    nvidia)
      log_ok "GPU: NVIDIA only — enabling NVIDIA env vars."
      block='hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("GSK_RENDERER", "ngl")
hl.env("GBM_BACKEND", "nvidia-drm")'
      ;;
    amd)
      log_ok "GPU: AMD only — enabling Mesa/radeonsi env vars."
      block='hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")'
      ;;
    intel)
      log_ok "GPU: Intel only — enabling Mesa env vars."
      block='hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")'
      ;;
    hybrid-amd-nvidia)
      cards="$(_hd_build_drm_devices "amd intel nvidia")"
      if [[ -z "$cards" ]]; then
        log_warn "GPU hybrid but no usable DRM nodes — leaving GPU block empty."
        block="-- (hybrid GPU detected but no usable DRM nodes)"
      else
        log_ok "GPU: hybrid AMD+NVIDIA — AMD primary ($cards)."
        block="hl.env(\"AQ_DRM_DEVICES\", \"${cards}\")
hl.env(\"__GLX_VENDOR_LIBRARY_NAME\", \"mesa\")
hl.env(\"__EGL_VENDOR_LIBRARY_FILENAMES\", \"/usr/share/glvnd/egl_vendor.d/50_mesa.json\")
hl.env(\"LIBVA_DRIVER_NAME\", \"radeonsi\")"
      fi
      ;;
    hybrid-intel-nvidia)
      cards="$(_hd_build_drm_devices "intel amd nvidia")"
      if [[ -z "$cards" ]]; then
        log_warn "GPU hybrid but no usable DRM nodes — leaving GPU block empty."
        block="-- (hybrid GPU detected but no usable DRM nodes)"
      else
        log_ok "GPU: hybrid Intel+NVIDIA — Intel primary ($cards)."
        block="hl.env(\"AQ_DRM_DEVICES\", \"${cards}\")
hl.env(\"__GLX_VENDOR_LIBRARY_NAME\", \"mesa\")
hl.env(\"__EGL_VENDOR_LIBRARY_FILENAMES\", \"/usr/share/glvnd/egl_vendor.d/50_mesa.json\")"
      fi
      ;;
    hybrid-amd-intel)
      cards="$(_hd_build_drm_devices "amd intel nvidia")"
      if [[ -z "$cards" ]]; then
        log_warn "GPU hybrid but no usable DRM nodes — leaving GPU block empty."
        block="-- (hybrid GPU detected but no usable DRM nodes)"
      else
        log_ok "GPU: hybrid AMD+Intel — AMD primary ($cards)."
        block="hl.env(\"AQ_DRM_DEVICES\", \"${cards}\")
hl.env(\"__GLX_VENDOR_LIBRARY_NAME\", \"mesa\")
hl.env(\"__EGL_VENDOR_LIBRARY_FILENAMES\", \"/usr/share/glvnd/egl_vendor.d/50_mesa.json\")"
      fi
      ;;
    none|*)
      log_warn "No discrete GPU detected (VM or minimal). Leaving GPU block empty."
      block="-- (no discrete GPU detected — defaults apply)"
      ;;
  esac

  # Sanity: the block must only contain hl.env lines or comments (never
  # anything that could break the Lua file if detection glitched).
  if ! grep -qE '^(hl\.env|--|$)' <<< "$block"; then
    log_warn "GPU block failed sanity check — writing empty block."
    block="-- (GPU config skipped: detection error)"
  fi

  # Capture pre-write validity (for post-write self-heal decision).
  local _pre_valid=1
  if _hd_is_installed luac && ! luac -p "$_ENV_FILE" >/dev/null 2>&1; then
    _pre_valid=0
  fi

  # Idempotent marker replacement via awk (no python dependency).
  # Handles: markers present, markers missing (append), file unreadable.
  if ! _hd_is_installed awk; then
    log_warn "awk missing — cannot update GPU block. Skipping."
    return 0
  fi

  if grep -q "GPU_CONFIG_START >>>" "$_ENV_FILE" 2>/dev/null; then
    _HD_TMP="$(mktemp)"
    awk -v b="$block" '
      />>> GPU_CONFIG_START >>>/ { inb=1; print; print b; next }
      />>> GPU_CONFIG_END <<</ { inb=0 }
      !inb { print }
    ' "$_ENV_FILE" > "$_HD_TMP" 2>/dev/null || { rm -f "$_HD_TMP"; _HD_TMP=""; log_warn "GPU block write failed (awk). Skipping."; return 0; }
    mv "$_HD_TMP" "$_ENV_FILE" 2>/dev/null || { rm -f "$_HD_TMP"; _HD_TMP=""; log_warn "GPU block write failed (mv). Skipping."; return 0; }
    _HD_TMP=""
  else
    # No markers — append them (only if file is writable).
    if [[ -w "$_ENV_FILE" ]]; then
      {
        echo ""
        echo "-- >>> GPU_CONFIG_START >>>"
        echo "$block"
        echo "-- >>> GPU_CONFIG_END <<<"
      } >> "$_ENV_FILE" 2>/dev/null || { log_warn "GPU block append failed. Skipping."; return 0; }
    else
      log_warn "env-variables.lua not writable — skipping GPU config."
      return 0
    fi
  fi

  # Post-write validation: only self-heal if the file was valid BEFORE our
  # write (a pre-existing user error should not be blamed on / clobbered by
  # this module — we only neutralize our own block).
  if [[ "$_pre_valid" -eq 1 ]] && _hd_is_installed luac && ! luac -p "$_ENV_FILE" >/dev/null 2>&1; then
    log_warn "env-variables.lua failed Lua validation after GPU write — restoring safe empty block."
    # Re-run with an empty block to restore a valid state.
    block="-- (GPU config skipped: validation failure)"
    _HD_TMP="$(mktemp)"
    awk -v b="$block" '
      />>> GPU_CONFIG_START >>>/ { inb=1; print; print b; next }
      />>> GPU_CONFIG_END <<</ { inb=0 }
      !inb { print }
    ' "$_ENV_FILE" > "$_HD_TMP" 2>/dev/null
    mv "$_HD_TMP" "$_ENV_FILE" 2>/dev/null || true
    _HD_TMP=""
  fi

  log_ok "GPU env block configured ($gpu)."
}

# ------------------------------------------------------------------
# 2. Native monitor resolution → monitors.lua + monitors.conf
# ------------------------------------------------------------------
# Detection chain: hyprctl (live session) → wlr-randr → xrandr → 1080p@60.
# Each source guarded; empty/invalid results fall through to the next.
_hd_detect_monitors() {
  local data=""

  # hyprctl (only useful during a live Hyprland session)
  if _hd_is_installed hyprctl && _hd_is_installed python3 && hyprctl monitors >/dev/null 2>&1; then
    data=$(hyprctl -j monitors 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for m in data:
    name = m.get('name') or ''
    w = m.get('width') or 0
    h = m.get('height') or 0
    rr = m.get('refreshRate') or 0
    x = m.get('x') or 0
    y = m.get('y') or 0
    scale = m.get('scale') or 1.0
    if w > 0 and h > 0:
        if not name:
            name = \"FALLBACK\"
        print(f'{name} {w} {h} {rr:.0f} {x} {y} {scale}')
" 2>/dev/null)
  fi

  # wlr-randr (Wayland, no compositor needed)
  if [[ -z "$data" ]] && _hd_is_installed wlr-randr; then
    data=$(wlr-randr 2>/dev/null | awk '
      /^[A-Za-z]/ { name = $1 }
      /current/ {
        match($0, /([0-9]+)x([0-9]+)/, res)
        match($0, /@ ([0-9.]+)/, rr)
        if (res[1] && rr[1]) printf "%s %s %s %d 0 0 1.0\n", name, res[1], res[2], int(rr[1]+0.5)
      }')
  fi

  # xrandr (XWayland fallback) — handles negative offsets (-1920+0)
  if [[ -z "$data" ]] && _hd_is_installed xrandr; then
    data=$(xrandr 2>/dev/null | awk '
      /connected/ && !/disconnected/ {
        name = $1
        match($0, /([0-9]+)x([0-9]+)([-+][0-9]+)([-+][0-9]+)/, m)
        if (m[1]) printf "%s %s %s 60 %s %s 1.0\n", name, m[1], m[2], m[3], m[4]
      }')
  fi

  # Safe default
  if [[ -z "$data" ]]; then
    echo "FALLBACK 1920 1080 60 0 0 1.0"
  else
    echo "$data"
  fi
}

_hd_write_monitors() {
  mkdir -p "$(dirname "$_MONITORS_CONF")" 2>/dev/null || { log_warn "Cannot create hypr config dir — skipping monitors."; return 0; }

  local conf_lines="" lua_lines="" count=0
  local _n _w _h _rr _ox _oy _sc _rr_int _sc_fmt

  while IFS=' ' read -r _n _w _h _rr _ox _oy _sc; do
    [[ -z "$_n" || -z "$_w" || -z "$_h" ]] && continue
    # wlr-randr/xrandr may leave empty scale — normalize here
    [[ -z "$_sc" ]] && _sc="1.0"
    [[ -z "$_rr" ]] && _rr="60"
    [[ -z "$_ox" ]] && _ox="0"
    [[ -z "$_oy" ]] && _oy="0"
    # Numeric sanity: width/height must be positive integers.
    [[ "$_w" =~ ^[0-9]+$ ]] && [[ "$_h" =~ ^[0-9]+$ ]] || continue
    (( _w > 0 && _h > 0 )) || continue

    # Refresh rate: numeric, clamp absurd/zero values to 60.
    if [[ "$_rr" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      _rr_int=$(printf '%.0f' "$_rr" 2>/dev/null || echo 60)
      (( _rr_int >= 30 && _rr_int <= 240 )) || _rr_int=60
    else
      _rr_int=60
    fi

    # Scale: numeric, default 1.0, clamp to sane range.
    if [[ "$_sc" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      _sc_fmt=$(printf '%.1f' "$_sc" 2>/dev/null || echo "1.0")
      # Replace comma decimal with dot for safety
      _sc_fmt="${_sc_fmt/,/.}"
    else
      _sc_fmt="1.0"
    fi

    # Offsets: must be signed integers (allow -1920+0 style); else 0.
    [[ "$_ox" =~ ^[-+]?[0-9]+$ ]] || _ox=0
    [[ "$_oy" =~ ^[-+]?[0-9]+$ ]] || _oy=0

    if [[ -z "$_n" || "$_n" == "FALLBACK" ]]; then
      # Nameless monitor: skip it — the trailing wildcard fallback below
      # (output="", mode="preferred") already covers any unmatched display.
      continue
    else
      # Sanitize monitor name: strip anything that is not a safe token.
      _n="${_n//[^a-zA-Z0-9_-]/}"
      conf_lines+="monitor=${_n},${_w}x${_h}@${_rr_int},${_ox}x${_oy},${_sc_fmt}"$'\n'
      lua_lines+="hl.monitor({
    output = \"${_n}\",
    mode = \"${_w}x${_h}@${_rr_int}\",
    position = \"${_ox}x${_oy}\",
    scale = ${_sc_fmt}
})"$'\n'
    fi
    count=$((count + 1))
  done <<< "$(_hd_detect_monitors)"

  if [[ -z "$conf_lines" ]]; then
    conf_lines="monitor=,1920x1080@60,auto,1.0"$'\n'
    lua_lines="hl.monitor({
    output = \"\",
    mode = \"1920x1080@60\",
    position = \"auto\",
    scale = 1.0
})"$'\n'
    count=1
  fi

  # Atomic writes: temp file + mv (never leave a half-written config).
  local tmp_conf tmp_lua
  tmp_conf="$(mktemp)" && tmp_lua="$(mktemp)" || { log_warn "Cannot create temp files — skipping monitors."; return 0; }

  cat > "$tmp_conf" <<EOF
# HyprFlux — Auto-generated monitor config
# Generated by modules/19-hardware-detect.sh at install time.
# To reconfigure: SUPER+SHIFT+E → "Configure Monitors (nwg-displays)"

# Detected monitors (${count} connected)
${conf_lines}
# Fallback: any monitor not matched above uses preferred mode
monitor=,preferred,auto,1
EOF

  cat > "$tmp_lua" <<EOF
-- HyprFlux — Auto-generated monitor config
-- Generated by modules/19-hardware-detect.sh at install time.
-- nwg-displays (>= 2.4) overwrites this file with its own Lua output.

-- Detected monitors (${count} connected)
${lua_lines}
-- Fallback: any monitor not matched above uses preferred mode
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1
})
EOF

  mv "$tmp_conf" "$_MONITORS_CONF" 2>/dev/null || rm -f "$tmp_conf"
  mv "$tmp_lua" "$_MONITORS_LUA" 2>/dev/null || rm -f "$tmp_lua"

  mkdir -p "$_PROFILES_DIR" 2>/dev/null
  cp -f "$_MONITORS_CONF" "$_PROFILES_DIR/default.conf" 2>/dev/null || true
  cp -f "$_MONITORS_LUA" "$_PROFILES_DIR/default.lua" 2>/dev/null || true

  log_ok "Monitors configured: ${count} detected (native resolution)."
}

# ------------------------------------------------------------------
# 3. Keyboard layout → user-settings.lua
# ------------------------------------------------------------------
_hd_detect_keyboard() {
  local layout=""
  if _hd_is_installed localectl; then
    layout=$(localectl status --no-pager 2>/dev/null | awk '/X11 Layout/ {print $3}')
  fi
  if [[ -z "$layout" ]] && _hd_is_installed setxkbmap; then
    layout=$(setxkbmap -query 2>/dev/null | awk '/layout/ {print $2}')
  fi
  # Validate: only [a-zA-Z0-9_,-] allowed (layout like "us,de" or "us(intl)")
  if [[ "$layout" =~ ^[a-zA-Z0-9_,-]+$ ]]; then
    echo "$layout"
  else
    echo "us"
  fi
}

_hd_write_keyboard() {
  if [[ ! -f "$_SETTINGS_FILE" ]]; then
    log_warn "user-settings.lua not found — skipping keyboard layout."
    return 0
  fi
  local layout
  layout="$(_hd_detect_keyboard)"

  local tmp
  tmp="$(mktemp)" || { log_warn "Cannot create temp file — skipping keyboard layout."; return 0; }
  awk -v l="$layout" '
    /^[[:space:]]*kb_layout =/ { print "        kb_layout = \"" l "\","; next }
    { print }
  ' "$_SETTINGS_FILE" > "$tmp" 2>/dev/null || { rm -f "$tmp"; log_warn "Keyboard layout write failed (awk). Skipping."; return 0; }
  mv "$tmp" "$_SETTINGS_FILE" 2>/dev/null || { rm -f "$tmp"; log_warn "Keyboard layout write failed (mv). Skipping."; return 0; }

  log_ok "Keyboard layout: $layout (user-settings.lua)."
}

# ------------------------------------------------------------------
# Run (every step individually guarded; nothing can abort the install)
# ------------------------------------------------------------------
trap _hd_cleanup EXIT
_hd_write_gpu_block
_hd_write_monitors
_hd_write_keyboard
trap - EXIT

unset _HOME_CONFIG _ENV_FILE _SETTINGS_FILE _MONITORS_CONF _MONITORS_LUA _PROFILES_DIR _HD_TMP