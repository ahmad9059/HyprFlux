#!/bin/bash
# Shared, policy-aware desktop sleep actions. Never write directly to sysfs.
# Usage: SleepAction.sh suspend|hibernate|sleep [--check]
# "sleep" prefers suspend if supported, otherwise hibernate (the sleep key).
set -u
action="${1:-}"
check="${2:-}"
case "$action" in suspend|hibernate|sleep) ;; *) exit 2 ;; esac
case "$check" in ''|--check) ;; *) exit 2 ;; esac

available() {
  local action="$1" method
  if [[ "$action" == hibernate ]]; then
    local cmdline="${HYPRFLUX_CMDLINE_FILE:-/proc/cmdline}"
    if grep -qw noresume "$cmdline" 2>/dev/null; then return 1; fi
    if [[ "${HYPRFLUX_ALLOW_HIBERNATE:-0}" != 1 ]]; then
      grep -qE '(^|[[:space:]])resume=[^[:space:]]+' "$cmdline" 2>/dev/null || return 1
    fi
    method=CanHibernate
  else
    method=CanSuspend
  fi
  busctl --system --json=short call org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager "$method" 2>/dev/null |
    jq -e '.data[0] == "yes" or .data[0] == "challenge"' >/dev/null 2>&1
}

if [[ "$action" == sleep ]]; then
  if available suspend; then action=suspend; else action=hibernate; fi
fi
if ! available "$action"; then
  [[ "$check" == --check ]] && exit 1
  notify-send -u critical -i dialog-warning "Sleep action unavailable" \
    "$action is disabled or has no configured resume path. No sleep operation was started."
  exit 1
fi
[[ "$check" == --check ]] && exit 0
exec systemctl "$action"
