# Hibernate fix, scripts, and reinstall requirements

Recorded 2026-11-08. Desktop changes: commit `802154b`.

## Is it fixed?

**Manual hibernation is verified on the current installation.** The laptop
powered off completely by itself, then restored the running desktop after the
user pressed power and selected Arch Linux. Keyboard/mouse and desktop operation
were confirmed; logs showed Wi-Fi reconnection and a successful hyprlock unlock.

**Lid-close is configured to use that hibernate path, but its own hardware test
is still pending.** Ordinary suspend is not fixed. Both s2idle and experimental
S3 failed real tests, so suspend and compound sleep modes remain disabled.
Opening the lid is not a verified power-on mechanism; it may require the power
button. Do not put the machine in a bag until it has fully powered off.

**Reinstalling Arch and installing HyprFlux does not yet reproduce the complete
fix automatically.** The repository contains the desktop scripts, tests, and
documentation. Several essential changes exist only under `/etc`, `/usr/local`,
and the boot partition on this installation. The current ISO installer also
needs changes before it can promise this hardware's hibernate behavior.

## Hardware and successful test

| Item | Tested configuration |
| --- | --- |
| Laptop | ASUS ROG Zephyrus G15 GA503QR |
| Firmware | GA503QR.418 |
| Integrated GPU | AMD Cezanne, PCI `0000:06:00.0` |
| Discrete GPU | NVIDIA RTX 3070 Mobile, PCI `0000:01:00.0` |
| Kernel / NVIDIA | `7.2.14-arch1-1` / `615.78.08` |
| Wireless | MediaTek `mt7921e` |
| Hibernate storage | 16 GiB disk swap partition; not the 4 GiB zram device |
| Desktop | Hyprland `0.57.1`, internal display and external DisplayPort monitor |

The successful request began at **11:49:49 +05:00**, with systemd returning after
restoration at **11:52:02**. The boot/session was restored, not freshly started.
The request and user confirmation are recorded locally in
`/var/lib/hyprflux/hibernate-platform-request.json`.

These results apply to this tested combination, not every ASUS/NVIDIA laptop or
future kernel/driver release. A different BIOS or reinstall needs validation.

## What failed, and what changed

1. **s2idle:** the machine failed to return usefully from real suspend.
2. **S3 experiment:** a BIOS-specific DSDT override exposed `deep`, but real S3
   still failed. Passing low-level PM test stages did not prove working sleep.
3. **Early hibernate attempts:** the image was written, but NVIDIA restoration
   failed with `nv_pmops_freeze` / `pci_pm_freeze ... returns -5`.
4. **Late NVIDIA loading:** remove NVIDIA kernel modules from the initramfs and
   load them after the root filesystem mounts. A subsequent test restored the
   desktop, but still required forced power-off and logged an `mt7921e` restore
   error `-110`.
5. **Successful combination:** normal `systemctl hibernate`,
   `HibernateMode=platform`, late NVIDIA loading, enabled nvidia-persistenced,
   and the required Wi-Fi unload/reload service. The laptop powered off by itself
   and restored successfully.

Several factors changed between tests. This establishes a working combination,
not proof that any one change alone fixed the power-off failure.

## Repository scripts: portable desktop behavior

Canonical files are under `.config/`; matching deployment copies live under
`base-dots/config/`.

| File | Responsibility |
| --- | --- |
| `hypr/scripts/SleepAction.sh` | Checks logind `CanSuspend` / `CanHibernate`, then invokes normal systemctl actions. `sleep` prefers supported suspend, otherwise hibernate. |
| `hypr/scripts/Hibernate.sh` | Compatibility entrypoint delegating to `SleepAction.sh hibernate`; supports `--check`. |
| `hypr/scripts/Wlogout.sh` | Hides unavailable Suspend/Hibernate actions, sizes cards for the focused monitor, cleans up its private temporary layout. |
| `hypr/configs/keybinds.lua` | Routes `XF86Sleep` through `SleepAction.sh sleep`. |
| `wlogout/layout`, `wlogout/style.css`, icons | Redesigned power menu with visible shortcut keys and distinct destructive-action hover. |
| `hypr/UserConfigs/window-rules.lua` | Wlogout background blur. |
| `utilities/sync-colors.sh` | Generates the menu's accent and destructive-action colors. |
| `utilities/sleep-lab.sh` | Low-level investigation only; **not** a desktop sleep action or installer setup tool. |

`SleepAction.sh` requires `busctl`, `jq`, and systemctl; notifications use
`notify-send`. A capability of `yes` or `challenge` permits the request, subject
to authorization. A failed query or a denied capability blocks it.
Hibernation additionally requires a nonempty `resume=` parameter and rejects
`noresume`. `HYPRFLUX_ALLOW_HIBERNATE=1` skips only the parameter requirement for
separately configured EFI HibernateLocation setups; it does not override policy
or make an untested resume setup safe.

These scripts **do not** create swap, rebuild an initramfs, configure the BIOS,
install driver workarounds, or write logind policy. Seeing a Hibernate button is
not proof of successful power-off and restoration.

## Machine-local configuration: must be recreated after reinstall

Back up existing files before adapting this configuration. Do not copy this
installation's disk UUIDs, partition numbers, or GPU paths onto another system.

### 1. Disk swap and boot-time resume

The current disk swap UUID is
`fd327571-c582-43f3-9767-ae8092c3c424`. This is **historical evidence only**;
reformatting swap normally changes its UUID. Discover the new target with
`swapon --show` and `lsblk -f`. Provide sufficient disk swap for the intended
hibernate workload. Zram cannot retain the image across power-off.

This machine uses a busybox/udev mkinitcpio initramfs with the `resume` hook after
`filesystems`, plus `resume=UUID=<actual-swap-uuid>` in `/etc/kernel/cmdline`.
The main UKI is `/boot/EFI/Linux/arch-linux.efi`. Rebuilding the UKI is necessary
after changing its embedded command line; editing GRUB's Linux arguments alone
does not update that embedded command line.

**The ISO uses a systemd-based initramfs instead.** Preserve its systemd resume
generator path; do not append the busybox `resume` hook blindly. An explicit,
correct `resume=` parameter can be used with that path and satisfies the desktop
guard. EFI HibernateLocation is another systemd mechanism, but was not the path
validated in this test. Swap files additionally require correct offset handling;
encrypted swap requires a resume-compatible persistent unlocking arrangement.

### 2. NVIDIA outside the initramfs

The current `/etc/mkinitcpio.conf` has `MODULES=()` rather than explicit early
NVIDIA modules. Check **all** mkinitcpio drop-ins for added NVIDIA modules as
well. Preserve storage drivers and the AMD display setup; do not delete unrelated
module configuration. After rebuilding, inspect the actual installed image:
NVIDIA **kernel modules** must be absent. NVIDIA firmware filenames alone are
not evidence that the kernel driver is loaded early.

`/etc/modules-load.d/nvidia.conf` contains:

```text
nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm
```

`nvidia-persistenced.service` is enabled. NVIDIA 615 uses kernel suspend notifiers
on this machine; legacy NVIDIA suspend/hibernate/resume services remain disabled.
Do not apply older-driver service recipes without checking the installed driver.

The live Hyprland GPU configuration resolves devices using PCI addresses,
instead of assuming stable `/dev/dri/cardN` numbering. Late driver loading changed
those numbers. This resolver is a **live personal configuration change**, not
an installer feature added by commit `802154b`. Preserve or regenerate it.

### 3. Required Wi-Fi pre/post service

These installed files are outside this repository:

- `/usr/local/libexec/hyprflux-hibernate-wifi`
- `/etc/systemd/system/hyprflux-hibernate-wifi.service`
- `/etc/systemd/system/systemd-hibernate.service.d/20-hyprflux-wifi.conf`

The helper checks whether `mt7921e` is loaded, removes it with
`modprobe -r mt7921e`, and records that fact in a private runtime directory. Its
post action reloads the module only if the pre action removed it. No forced
module removal is used.

The oneshot service uses `RemainAfterExit=yes`,
`RuntimeDirectory=hyprflux-hibernate-wifi`, `RuntimeDirectoryMode=0700`,
`StopWhenUnneeded=yes`, and `Before=systemd-hibernate.service`. `ExecStart` runs
the helper's `pre` action; `ExecStop` runs `post`. The hibernate service drop-in
sets both `Requires=hyprflux-hibernate-wifi.service` and
`After=hyprflux-hibernate-wifi.service`.

This ordering makes removal failure prevent hibernation, then reloads Wi-Fi after
the hibernate operation finishes. An unordered system-sleep hook whose failures
are ignored is not equivalent. Recreate and verify these files as a unit.

### 4. Persistent sleep and lid policy

`/etc/systemd/sleep.conf.d/10-hyprflux-no-sleep.conf` now contains:

```ini
[Sleep]
AllowSuspend=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
AllowHibernation=yes
HibernateMode=platform
```

The old filename is retained, but it no longer disables hibernation.
`/etc/systemd/logind.conf.d/10-hyprflux-lid.conf` contains:

```ini
[Login]
HandleLidSwitch=hibernate
HandleLidSwitchExternalPower=hibernate
HandleLidSwitchDocked=hibernate
HandleSuspendKey=ignore
HandleHibernateKey=ignore
```

The desktop handles its sleep key. Lid-close hibernates even with AC/external
displays; it is intentionally not a keep-running clamshell policy. The live
logind configuration was reloaded using SIGHUP **with the lid open**, without
restarting the login session. Hypridle provides pre-sleep locking through its
sleep delay inhibitor; retain and test that behavior.

### 5. Boot menu and unsuccessful S3 experiment

`/etc/grub.d/15_uki` emits explicit chainloader entries: main Arch Linux first,
previous-image fallback second. The local paths are `/EFI/Linux/arch-linux.efi`
and `/EFI/Linux/arch-fallback.efi`. The Parrot entry was preserved. This is also
outside the repository; a fresh installer must generate entries appropriate to
its own layout instead of copying this machine's GRUB file or ESP UUID.

The experimental `/etc/initcpio/acpi_override/dsdt-s3.aml`, its build hook, and
`mem_sleep_default=deep` remain on the current system. **They did not fix S3 and
are not established requirements for hibernation.** Do not ship this BIOS-specific
AML as a general default. Removing it on the current machine needs a backed-up
UKI rebuild and a separate boot/hibernate test; no removal test has been done.

## Current HyprFlux-ISO gaps

Read-only review of the sibling `HyprFlux-ISO` source on 2026-11-08 found:

| Source | Current behavior / gap |
| --- | --- |
| `airootfs/root/hyprflux-install.sh` | Pins `HYPRFLUX_REF=74735688a2703a717694518b5699e79991c33a74`, not the new desktop commit. Swap is optional; creating it alone does not establish this hibernate setup. |
| `airootfs/root/lib/hyprflux-chroot-wrapper.sh` | Writes `MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)` into `/etc/mkinitcpio.conf.d/90-hyprflux-nvidia.conf`; conflicts with the late-loading approach tested here. |
| `airootfs/root/lib/configure-initramfs.sh` | Builds a systemd-based initramfs; resume configuration must follow that design, not blindly copy the current busybox hook list. |
| ISO live `logind.conf.d/do-not-suspend.conf` | Live-media safety policy, not the installed-machine hibernate policy. Keep these scopes separate. |

The normal HyprFlux `base-installer/install-scripts/nvidia.sh` also adds early
NVIDIA modules. `modules/16-hardware-detect.sh` writes detected card paths into
GPU configuration; it does not install the live PCI-address resolver described
above. Neither installer currently installs the complete machine-local fix.

**No ISO files were changed for this documentation task.** A local HyprFlux
commit is not available to an online installer until published, and publishing
alone does not update the ISO's pinned revision. This review describes source
files, not an acceptance test of an already-built image under `out/`.

## Recommended hardware-profile integration (not implemented)

1. Add an explicit GA503QR hardware profile, gated by detected machine identity
   and compatible hardware. Do not silently apply it to all NVIDIA machines.
2. Configure real swap and derive its actual UUID after partitioning. Generate
   the installed boot/resume configuration for the chosen UKI/GRUB and initramfs
   design. Preserve a recoverable boot entry.
3. For the tested driver path, suppress conflicting early NVIDIA configuration,
   install normal-stage module loading, and verify the resulting image.
4. Install the Wi-Fi helper, service, dependency drop-in, and sleep policy
   idempotently. Do not unload the live installer Wi-Fi driver during an online
   installation. Configure the target only.
5. Generate GPU selection from stable device identity. Do not bake in card numbers
   or assume another machine has this one's PCI layout.
6. Do not bundle the failed S3 ACPI experiment. Start with firmware defaults;
   validate the clean profile on the actual laptop.
7. Publish a reviewed HyprFlux revision and update the ISO's exact pin. Add tests
   for the target files and final initramfs. Build/VM checks alone cannot prove
   laptop firmware power-off or GPU/Wi-Fi restoration.
8. Verify manual hibernate first. Enable automatic lid hibernate only after that
   succeeds, then perform the separate lid-cycle acceptance test.

Until this is implemented and hardware-tested, treat a reinstall as requiring
manual reconstruction and validation, not as a guaranteed carry-over of the fix.

## Validation and recovery checklist

Before testing, save all work and back up the boot images and edited files.
Keep a working fallback/recovery path. Do not force a transition just to bypass
a failed capability check.

Read-only checks:

```bash
swapon --show
cat /proc/cmdline
cat /sys/power/resume
busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate
systemctl cat systemd-hibernate.service hyprflux-hibernate-wifi.service
systemd-inhibit --list
journalctl -b -u systemd-hibernate.service -u hyprflux-hibernate-wifi.service
```

After explicit approval, use **normal `systemctl hibernate`**, not sleep-lab's
direct sysfs operation. Confirm complete automatic power-off, then power on into
the correct boot entry. Confirm the same applications/session, lock screen,
keyboard, mouse, internal/external monitors, and Wi-Fi. Inspect logs for errors.
Only then test lid-close and repeat those checks. Recheck after material kernel,
driver, firmware, or boot configuration changes.

If an attempt hangs, record it as failed; dark screens or a returned command are
not proof of success. Do not assume the image is safely saved before forcing
power off. Use a known-good fallback or recovery medium if normal boot fails.
Restore backed-up configuration as a coherent set and rebuild the applicable
boot image rather than mixing old hooks with new command lines. Do not boot
another OS that writes shared filesystems while intending to restore a
hibernated session.

Safe repository regression tests (no real power transitions):

```bash
python -m unittest discover -s tests -p 'test_wlogout.py' -v
python -m unittest discover -s tests -p 'test_sleep_lab.py' -v
```

Backups on the current installation are in `~/dotfiles_backup/`, including
`hibernate-final-policy-20261108-115754`. The NVIDIA late-load backup is under
`/root/dotfiles_backup/nvidia-late-20261108-112629`. These local backups are not
included in a Git clone; preserve them separately before wiping the installation.

## Related records

- [Investigation and hardware results](LID-AND-SLEEP-2026-11-08.md)
- [Power-menu design and usage](WLOGOUT-2026-11-08.md)
- https://docs.kernel.org/power/basic-pm-debugging.html
- https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate
- https://www.freedesktop.org/software/systemd/man/latest/systemd-sleep.conf.html
- https://www.freedesktop.org/software/systemd/man/latest/logind.conf.html
