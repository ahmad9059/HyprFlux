#!/bin/bash
# HyprFlux — https://github.com/ahmad9059/HyprFlux
# Sleep lab: run ONE real suspend test and keep the evidence on disk.
# LOW-LEVEL DEBUGGING ONLY: direct sysfs writes bypass logind locking,
# inhibitors and systemd pre/post-sleep hooks. Do not use this for normal sleep.
#
#   sudo sleep-lab.sh status
#   sudo sleep-lab.sh test [-s SECONDS] [-S mem|freeze|disk] [-M deep|s2idle] [-D MODE] [-p LEVEL]
#
# A test writes START to the log and syncs it before the machine sleeps. If the
# machine never comes back, the log keeps START without END. This means the
# result is incomplete; it is not proof of a hardware hang. Nothing here changes configuration; it
# writes to /sys/power for the duration of one test and restores it.
#
#   -s  seconds until the RTC alarm wakes the machine (default 30)
#   -S  kernel sleep state: mem (default), freeze, or disk (hibernate)
#   -D  hibernate mode for -S disk: shutdown (default, plain power-off), platform, reboot.
#       A real hibernate needs a registered resume device and the machine is
#       powered on by hand; when it resumes, the test continues and logs END.
#   -M  mem_sleep mode for this boot: deep (S3) or s2idle
#   -p  pm_test level: none (default), freezer, devices, platform, processors, core.
#       Levels stop short of real sleep, so a failure shows which stage is broken.

set -u

LOG="${SLEEP_LAB_LOG:-/var/lib/hyprflux/sleep-lab.log}"
POWER="${SLEEP_LAB_POWER:-/sys/power}"

stamp() { date -Is; }

log() {
  mkdir -p "$(dirname -- "$LOG")"
  printf '%s\t%s\n' "$(stamp)" "$*" >>"$LOG"
  sync -f "$LOG" 2>/dev/null || sync
}

first_value() { grep -m1 -o "$1" 2>/dev/null; }

status() {
  [[ -f "$LOG" ]] || { echo "No sleep tests recorded yet."; return 0; }
  echo "mem_sleep: $(cat "$POWER/mem_sleep" 2>/dev/null)   hw sleep last cycle: $(cat "$POWER/suspend_stats/last_hw_sleep" 2>/dev/null)"
  echo "--- tests"
  awk -F'\t' '
    $2 ~ /^START / { split($2, a, " "); id = a[2]; started[id] = $0; order[++n] = id }
    $2 ~ /^END /   { split($2, a, " "); ended[a[2]] = $0 }
    END {
      for (i = 1; i <= n; i++) {
        id = order[i]; split(started[id], s, "\t")
        if (id in ended) { split(ended[id], e, "\t"); print e[1] "\t" e[2] }
        else print s[1] "\t" "INCOMPLETE " id " (no completion record): " substr(s[2], index(s[2], " ") + length(id) + 2)
      }
    }' "$LOG" | tail -n 15
}

health() {
  local bad=()
  # Disk: a direct write and read back through the same device the system runs from.
  local probe; probe="$(mktemp /var/tmp/sleep-lab.XXXXXX)" || probe=
  if [[ -n "$probe" ]]; then
    dd if=/dev/urandom of="$probe" bs=1M count=8 oflag=direct status=none 2>/dev/null && sync &&
      [[ "$(stat -c %s "$probe")" -eq 8388608 ]] || bad+=("disk-write")
    rm -f "$probe"
  else
    bad+=("disk-tmp")
  fi
  local inputs; inputs="$(grep -c '^N: Name=' /proc/bus/input/devices 2>/dev/null)"
  [[ "${inputs:-0}" -ge "${SLEEP_LAB_MIN_INPUTS:-6}" ]] || bad+=("input-devices=${inputs:-0}")
  local connected; connected="$(grep -l '^connected' /sys/class/drm/card*-*/status 2>/dev/null | wc -l)"
  [[ "$connected" -ge 1 ]] || bad+=("no-display-connected")
  if command -v nvidia-smi >/dev/null 2>&1; then
    timeout 20 nvidia-smi -L >/dev/null 2>&1 || bad+=("nvidia-smi")
  fi
  ip -o link show 2>/dev/null | grep -q 'wl' || bad+=("wifi-missing")
  printf '%s' "${bad[*]:-}"
}

kernel_evidence() { # $1 = epoch seconds when the test started
  journalctl -k --since "@$1" --no-pager -o cat 2>/dev/null |
    grep -E 'PM: (suspend|resume|hibernation)|ERROR|Failed|failed|timeout|timed out|Xid|NVRM|DMCUB|reset' |
    grep -v 'Marking nosave pages' |
    grep -v -E 'ACPI BIOS Error|ACPI Error'
}

run_test() {
  local seconds=30 state=mem mode="" level=none opt disk=shutdown
  while getopts "s:S:M:p:D:" opt; do
    case "$opt" in
      s) seconds="$OPTARG" ;;
      S) state="$OPTARG" ;;
      M) mode="$OPTARG" ;;
      p) level="$OPTARG" ;;
      D) disk="$OPTARG" ;;
      *) echo "usage: $0 test [-s SECONDS] [-S mem|freeze|disk] [-M deep|s2idle] [-D shutdown|platform|reboot] [-p LEVEL]" >&2; return 2 ;;
    esac
  done
  [[ "$seconds" =~ ^[0-9]+$ && "$seconds" -ge 10 ]] || { echo "seconds must be a number >= 10" >&2; return 2; }
  [[ "$state" == mem || "$state" == freeze || "$state" == disk ]] || { echo "state must be mem, freeze or disk" >&2; return 2; }
  case "$disk" in shutdown | platform | reboot) ;; *) echo "unknown hibernate mode: $disk" >&2; return 2 ;; esac
  case "$level" in none | freezer | devices | platform | processors | core) ;; *) echo "unknown pm_test level: $level" >&2; return 2 ;; esac
  [[ "$EUID" -eq 0 ]] || { echo "run as root (sudo)" >&2; return 1; }
  exec 9>/run/hyprflux-sleep-lab.lock; flock -n 9 || { echo "another sleep test is running" >&2; return 1; }

  if [[ -n "$mode" ]]; then
    grep -qw "$mode" "$POWER/mem_sleep" || { echo "mem_sleep does not offer '$mode': $(cat "$POWER/mem_sleep")" >&2; return 1; }
    echo "$mode" >"$POWER/mem_sleep" || return 1
  fi

  local id started elapsed rc modules verdict problems evidence failures_before failures_after
  id="$(date +%s)"; started="$id"
  failures_before="$(cat "$POWER/suspend_stats/failed_resume" 2>/dev/null || echo 0)"
  modules="$(lsmod | awk '$1 ~ /^(amd_pmc|nvidia|amdgpu|nvme|xhci_pci|mt7921e|asus_nb_wmi)$/ {printf "%s ", $1}')"
  if [[ "$state" == disk ]]; then
    grep -qw "$disk" "$POWER/disk" || { echo "hibernate mode '$disk' not offered: $(cat "$POWER/disk")" >&2; return 1; }
    [[ -s "$POWER/resume" && "$(cat "$POWER/resume")" != "0:0" ]] || { echo "no resume device registered: hibernating would lose the session" >&2; return 1; }
    echo "$disk" >"$POWER/disk" || return 1
  fi
  log "START $id state=$state disk=$disk mem_sleep=\"$(cat "$POWER/mem_sleep")\" pm_test=$level seconds=$seconds kernel=$(uname -r) modules=[${modules% }] cmdline=\"$(cat /proc/cmdline)\""

  echo "$level" >"$POWER/pm_test" 2>/dev/null
  # pm_test levels wake themselves after a few seconds. Real suspend needs the RTC alarm.
  # A real hibernate powers off: it is resumed by the user booting the machine again.
  if [[ "$level" == none && "$state" != disk ]]; then
    rtcwake -m no -s "$seconds" >/dev/null 2>&1 || { log "END $id verdict=ERROR rtc-alarm-failed"; echo none >"$POWER/pm_test"; return 1; }
  fi
  sync
  echo "$state" >"$POWER/state"; rc=$?
  elapsed=$(( $(date +%s) - started ))
  echo none >"$POWER/pm_test" 2>/dev/null
  log "RESUMED $id rc=$rc elapsed=${elapsed}s hw_sleep=$(cat "$POWER/suspend_stats/last_hw_sleep" 2>/dev/null) failed_resume=$(cat "$POWER/suspend_stats/failed_resume" 2>/dev/null) last_failed_dev=$(cat "$POWER/suspend_stats/last_failed_dev" 2>/dev/null)"

  sleep 3
  problems="$(health)"
  failures_after="$(cat "$POWER/suspend_stats/failed_resume" 2>/dev/null || echo 0)"
  if [[ "$failures_before" =~ ^[0-9]+$ && "$failures_after" =~ ^[0-9]+$ ]] && ((failures_after > failures_before)); then
    problems+=" kernel-resume-failures=$((failures_after - failures_before))"
  fi
  evidence="$(kernel_evidence "$started")"
  if grep -qiE '\*ERROR\*|returns -[0-9]+|IB test failed|Flip event timeout|failed to (resume|restore|suspend)' <<<"$evidence"; then
    problems+=" kernel-driver-errors"
  fi
  [[ -n "$evidence" ]] && while IFS= read -r line; do log "KERNEL $id $line"; done <<<"$evidence"
  if [[ "$rc" -ne 0 ]]; then verdict="FAIL(write-rc=$rc)"
  elif [[ -n "$problems" ]]; then verdict="DEGRADED($problems)"
  elif [[ "$level" == none ]]; then
    # Returning proves resume, NOT automatic power-off, working input or low battery drain.
    verdict="RESUMED_NEEDS_USER_CHECK"
  else verdict="RETURNED_FROM_PM_TEST"; fi
  log "END $id verdict=$verdict slept=${elapsed}s"
  echo "$verdict (slept ${elapsed}s)"
  [[ "$verdict" == RESUMED_NEEDS_USER_CHECK || "$verdict" == RETURNED_FROM_PM_TEST ]]
}

case "${1:-}" in
  status) status ;;
  test) shift; run_test "$@" ;;
  *) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
