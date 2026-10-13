#!/bin/bash
# ============================================================
# modules/09-plymouth.sh — HyprFlux Plymouth theme + hooks
# ============================================================
# Edge-case hardened:
#   - plymouth failure is cosmetic — NEVER aborts the install
#   - removes any existing HyprFlux plymouth theme first (idempotent)
#   - validates extracted theme (hyprflux.plymouth + hyprflux.script)
#   - verifies the theme is actually set as default (plymouthd.conf)
#   - mkinitcpio HOOKS edit is duplicate-safe (won't double-add)
#   - GRUB "quiet splash" handling is idempotent (no dup tokens)
# ============================================================
should_skip "plymouth" && return 0

log_action "Installing Plymouth..."

# 1. plymouth package is guaranteed by base-installer 01-hypr-pkgs — just verify.
if ! pacman -Qi plymouth &>/dev/null; then
  log_warn "plymouth package missing — skipping Plymouth theme setup."
  return 0
fi

_plymouth_theme_archive="${PLYMOUTH_THEME_ARCHIVE:-$REPO_DIR/utilities/hyprflux-plymouth.tar.xz}"
_plymouth_theme_dir="${PLYMOUTH_THEME_DIR:-/tmp/hyprflux-plymouth}"
_plymouth_theme_name="${PLYMOUTH_THEME_NAME:-hyprflux}"
_plymouth_dest="/usr/share/plymouth/themes"
_plymouth_theme_dest="$_plymouth_dest/$_plymouth_theme_name"
_mkinitcpio_conf="/etc/mkinitcpio.conf"
_grub_conf="/etc/default/grub"
_grub_cmdline=""

# Insert "plymouth" into the HOOKS array at the correct position: after udev
# (else systemd, else base). Plymouth MUST come after those — placing it first
# makes mkinitcpio warn that the hook cannot find the shell it runs with and
# the theme never appears. Idempotent: re-places it if already present.
_plymouth_ensure_hook() {
  local conf="$1"
  [[ -f "$conf" ]] || { log_warn "$conf not found — cannot enable plymouth hook."; return 0; }

  local hooks
  hooks="$(grep -E '^[[:space:]]*HOOKS=\(' "$conf" | head -n1 \
           | sed -E 's/^[[:space:]]*HOOKS=\(//; s/\).*$//')"
  if [[ -z "$hooks" ]]; then
    log_warn "Could not parse HOOKS= in $conf — cannot enable plymouth hook."
    return 0
  fi

  # Drop any existing plymouth token so it can be re-placed correctly.
  local cleaned="" h
  for h in $hooks; do
    [[ "$h" == "plymouth" ]] && continue
    cleaned+="$h "
  done
  cleaned="${cleaned% }"

  # Anchor: after udev, else systemd, else base.
  local anchor="" cand
  for cand in udev systemd base; do
    for h in $cleaned; do
      [[ "$h" == "$cand" ]] && { anchor="$cand"; break; }
    done
    [[ -n "$anchor" ]] && break
  done

  local new="" placed=0
  for h in $cleaned; do
    new+="$h "
    if [[ "$placed" -eq 0 && -n "$anchor" && "$h" == "$anchor" ]]; then
      new+="plymouth "
      placed=1
    fi
  done
  [[ "$placed" -eq 1 ]] || new="plymouth $new"
  new="${new% }"

  if [[ "$new" == "$hooks" ]]; then
    log_info "Plymouth hook already correctly placed in HOOKS."
    return 0
  fi

  if sudo sed -i -E "s|^[[:space:]]*HOOKS=\(.*|HOOKS=($new)|" "$conf"; then
    log_ok "Plymouth hook placed after ${anchor:-the first hook} in HOOKS."
  else
    log_warn "Failed to update HOOKS in $conf — add 'plymouth' manually."
  fi
}

# 2. Archive present + valid?
if [[ ! -f "$_plymouth_theme_archive" ]]; then
  log_warn "Plymouth theme archive not found at $_plymouth_theme_archive. Skipping."
  return 0
fi
if ! tar -tJf "$_plymouth_theme_archive" >/dev/null 2>&1; then
  log_warn "Plymouth theme archive is corrupt/unreadable. Skipping."
  return 0
fi

# 3. Fresh extract (remove stale dir first)
rm -rf "$_plymouth_theme_dir"
mkdir -p "$_plymouth_theme_dir" || { log_warn "Cannot create $_plymouth_theme_dir. Skipping."; return 0; }

if ! tar -C "$_plymouth_theme_dir" --strip-components=1 -xJf "$_plymouth_theme_archive" 2>/dev/null; then
  log_warn "Failed to extract Plymouth theme archive. Skipping."
  return 0
fi

# 4. Validate extracted theme (requires .plymouth + .script files)
if [[ ! -f "$_plymouth_theme_dir/$_plymouth_theme_name.plymouth" ]] || \
   [[ ! -f "$_plymouth_theme_dir/$_plymouth_theme_name.script" ]]; then
  log_warn "Extracted theme missing ${_plymouth_theme_name}.plymouth/.script — skipping."
  return 0
fi
log_ok "Theme archive extracted and validated."

# 5. Remove any previous HyprFlux theme, then install fresh
sudo mkdir -p "$_plymouth_dest"
if [[ -d "$_plymouth_theme_dest" ]]; then
  log_info "Removing previous $_plymouth_theme_name theme..."
  sudo rm -rf "$_plymouth_theme_dest"
fi

if ! sudo cp -r "$_plymouth_theme_dir" "$_plymouth_theme_dest"; then
  log_warn "Failed to copy Plymouth theme. Skipping."
  return 0
fi

# Verify the copy actually landed
if [[ ! -f "$_plymouth_theme_dest/$_plymouth_theme_name.plymouth" ]]; then
  log_warn "Plymouth theme copy verification failed. Skipping."
  return 0
fi
log_ok "Theme '$_plymouth_theme_name' installed."

# 6. Enable Plymouth in mkinitcpio at the correct position (after base/udev).
if [[ -f "$_mkinitcpio_conf" ]]; then
  _plymouth_ensure_hook "$_mkinitcpio_conf"
else
  log_warn "$_mkinitcpio_conf not found — cannot enable plymouth hook."
fi

# 7. Set Plymouth theme as default (with verification)
if command -v plymouth-set-default-theme &>/dev/null; then
  log_action "Setting Plymouth theme to '$_plymouth_theme_name'..."
  sudo plymouth-set-default-theme "$_plymouth_theme_name" >/dev/null 2>&1 || \
    log_warn "plymouth-set-default-theme failed."

  # Verify via plymouthd.conf (Theme= line)
  if grep -qE "^Theme=$_plymouth_theme_name$" /etc/plymouth/plymouthd.conf 2>/dev/null; then
    log_ok "Plymouth theme set to $_plymouth_theme_name."
  else
    # Fallback: write plymouthd.conf directly
    if [[ -w /etc/plymouth/plymouthd.conf ]] || sudo -n true 2>/dev/null; then
      sudo sed -i "s/^Theme=.*/Theme=$_plymouth_theme_name/" /etc/plymouth/plymouthd.conf 2>/dev/null || true
      if ! grep -q "^Theme=" /etc/plymouth/plymouthd.conf 2>/dev/null; then
        echo "Theme=$_plymouth_theme_name" | sudo tee -a /etc/plymouth/plymouthd.conf >/dev/null 2>&1 || true
      fi
      log_ok "Plymouth theme set via plymouthd.conf."
    else
      log_warn "Could not verify/force theme in plymouthd.conf."
    fi
  fi
else
  log_warn "plymouth-set-default-theme not found — theme files installed but not activated."
fi

# 8. GRUB cmdline: ensure "quiet splash" present (idempotent, no dup tokens)
if [[ -f "$_grub_conf" ]]; then
  log_action "Ensuring 'quiet splash' are enabled in GRUB..."
  _grub_cmdline="$(grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$_grub_conf" | head -n1 | cut -d'"' -f2 || true)"

  if [[ -n "$_grub_cmdline" ]]; then
    # Add missing tokens one at a time (avoids duplicates)
    if [[ "$_grub_cmdline" != *quiet* ]]; then
      _grub_cmdline="quiet $_grub_cmdline"
    fi
    if [[ "$_grub_cmdline" != *splash* ]]; then
      _grub_cmdline="$_grub_cmdline splash"
    fi
    # Trim leading/trailing spaces
    _grub_cmdline="${_grub_cmdline#"${_grub_cmdline%%[![:space:]]*}"}"
    _grub_cmdline="${_grub_cmdline%"${_grub_cmdline##*[![:space:]]}"}"
    sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$_grub_cmdline\"|" "$_grub_conf"
    log_ok "GRUB_CMDLINE_LINUX_DEFAULT updated: '$_grub_cmdline'"
  else
    # No existing GRUB_CMDLINE_LINUX_DEFAULT — add it
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' | sudo tee -a "$_grub_conf" >/dev/null
    log_ok "GRUB_CMDLINE_LINUX_DEFAULT added: 'quiet splash'"
  fi
else
  log_warn "$_grub_conf not found — skipping GRUB config update."
fi

# 8b. Unified kernel images (UKIs) ignore GRUB_CMDLINE_LINUX_DEFAULT.
#     GRUB's 10_linux prefers a UKI in /boot/EFI/Linux/ and boots it with the
#     cmdline embedded at build time, so kernel options must live in
#     /etc/kernel/cmdline (read by mkinitcpio's uki presets). Detect a UKI
#     setup and merge the GRUB cmdline (plus quiet/splash and the cursor
#     setting) into /etc/kernel/cmdline so the Plymouth theme actually shows.
_kernel_cmdline="/etc/kernel/cmdline"
_has_uki=0
if compgen -G "/boot/EFI/Linux/*.efi" >/dev/null 2>&1; then _has_uki=1; fi
if grep -qE '^[[:space:]]*(default_uki|fallback_uki)=' /etc/mkinitcpio.d/*.preset 2>/dev/null; then
  _has_uki=1
fi

if [[ "$_has_uki" -eq 1 ]]; then
  log_action "Unified kernel image detected — configuring /etc/kernel/cmdline..."

  # Neutralize any baked-in Arch logo splash in the mkinitcpio preset so the
  # HyprFlux Plymouth theme is the only boot splash.
  for _preset in /etc/mkinitcpio.d/*.preset; do
    [[ -f "$_preset" ]] || continue
    if grep -qE '^[^#]*--splash([= ])' "$_preset" 2>/dev/null; then
      sudo sed -i -E 's|^([^#]*--splash.*)$|# &   # hyprflux: disabled (plymouth theme is used)|' "$_preset" \
        && log_ok "Disabled preset boot-splash in $_preset."
    fi
  done

  if [[ ! -e "$_kernel_cmdline" ]]; then
    log_warn "$_kernel_cmdline not found — skipping (cannot safely create it)."
  else
    # Preserve everything already there (e.g. root=UUID=...), then add the
    # missing tokens. Never drops existing tokens.
    _kc_current="$(tr '\n' ' ' < "$_kernel_cmdline" 2>/dev/null || true)"
    _new_kc=""
    for _tok in $_kc_current quiet splash vt.global_cursor_default=0 $_grub_cmdline; do
      [[ -z "$_tok" ]] && continue
      case " $_new_kc " in
        *" $_tok "*) ;;
        *) _new_kc+="$_tok " ;;
      esac
    done
    _new_kc="${_new_kc% }"

    if [[ "$_new_kc" != "$_kc_current" && -n "$_new_kc" ]]; then
      if printf '%s\n' "$_new_kc" | sudo tee "$_kernel_cmdline" >/dev/null; then
        log_ok "/etc/kernel/cmdline updated: '$_new_kc'"
      else
        log_warn "Failed to update $_kernel_cmdline."
      fi
    else
      log_info "/etc/kernel/cmdline already has the required options."
    fi
  fi
else
  log_info "Classic initramfs (no UKI) — /etc/default/grub controls boot options."
fi


log_action "Rebuilding initramfs..."
if sudo mkinitcpio -P >/dev/null 2>&1; then
  log_ok "Initramfs rebuilt successfully."
else
  log_warn "Failed to rebuild initramfs. You may need to run 'sudo mkinitcpio -P' manually."
fi

log_ok "Plymouth with theme '$_plymouth_theme_name' is ready! Reboot to see it."

unset _plymouth_theme_archive _plymouth_theme_dir _plymouth_theme_name _plymouth_dest
unset _plymouth_theme_dest _mkinitcpio_conf _grub_conf _grub_cmdline
unset _kernel_cmdline _has_uki _preset _kc_current _new_kc _tok
unset -f _plymouth_ensure_hook 2>/dev/null || true
return 0
