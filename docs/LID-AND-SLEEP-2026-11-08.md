# Laptop sleep — manual hibernate verified, lid cycle pending

For the complete script map, reinstall requirements, and current ISO gaps, see
[Hibernate fix and reinstall guide](HIBERNATE-FIX-AND-REINSTALL.md).

## Scope and current status

Machine: ASUS ROG Zephyrus G15 GA503QR, BIOS 418, AMD Cezanne iGPU,
NVIDIA RTX 3070 Mobile, Arch Linux kernel 7.2.14, NVIDIA 615.78.08.
The target is working battery-saving lid behavior, not just turning off the screen.
Normal systemd platform-mode hibernation now powers off automatically and restores
the desktop, confirmed by the user after the 11:49:49 test (return 11:52:02).
The same boot/session resumed, Wi-Fi reconnected, and hyprlock unlocked.
Lid-close now requests hibernate, including on AC and with external displays.
**A real lid-close/open cycle is still pending.** Confirm complete power-off
before putting the laptop in a bag. Opening the lid may not power it on; use the
power button and select Arch Linux if needed.

## Observed results

- The original s2idle attempt ended with `PM: suspend entry (s2idle)`; the
  user subsequently needed a forced restart. The log does not identify the
  failing hardware component.
- A machine-specific ACPI override exposed S3 (`s2idle [deep]`). Booting that
  image worked. Real S3 still did not resume. This experiment is **not a fix**.
- Low-level PM test stages returned, but some reported AMD GPU errors. Earlier
  `PASS` labels in the diagnostic log were too weak and must not be interpreted
  as successful end-to-end sleep tests.
- First hibernate wrote an image, but restoration failed with NVIDIA
  `pci_pm_freeze ... returns -5` while NVIDIA was loaded in the initramfs.
- After removing NVIDIA kernel modules from the initramfs, loading them after
  root mount, and enabling nvidia-persistenced, the next image restored the
  original running session. **The machine still failed to power off by itself.**
- That restore also logged `mt7921e ... failed to restore async: error -110`.
  Counting input devices and seeing a Wi-Fi interface was not sufficient health
  verification. Input responsiveness and Wi-Fi reconnection need manual checks.

## Changes confined to this live machine

- `/etc/kernel/cmdline`: explicit swap resume location and experimental S3 default.
- `/etc/mkinitcpio.conf`: resume and ACPI override hooks; explicit NVIDIA early
  module loading removed. The rebuilt image retains the AMD console driver.
- `/etc/initcpio/acpi_override/dsdt-s3.aml`: experimental, specific to this BIOS.
  It must be removed or regenerated before a BIOS update. Do not distribute this
  table as a generic installer default.
- `/etc/modules-load.d/nvidia.conf`: load NVIDIA after root mount.
- Live Hyprland GPU selection resolves PCI-address paths, not unstable card numbers.
- `/etc/systemd/sleep.conf.d/10-hyprflux-no-sleep.conf`: allows only hibernation,
  with `HibernateMode=platform`; failed suspend/compound modes remain disabled.
- `/etc/systemd/logind.conf.d/10-hyprflux-lid.conf`: hibernate on lid-close in all
  power/display states. Reloaded with SIGHUP while the lid was open.
- NVIDIA 615 uses kernel suspend notifiers. Do not blindly enable legacy NVIDIA
  suspend services based on instructions for older driver releases.

## GRUB ordering

`/etc/grub.d/15_uki` now emits explicit chainloader entries in this order:
`Arch Linux` (`hyprflux-arch`), then the fallback (`hyprflux-arch-fallback`).
It no longer relies on the `uki` scanner's file ordering. The main path is
`/EFI/Linux/arch-linux.efi`; the fallback is `/EFI/Linux/arch-fallback.efi`.
The existing Parrot entry remains. Generated GRUB syntax and entry order were
checked; the user selected the main Arch entry in the successful test.

## Successful manual test and next controlled test

Use the normal `systemctl hibernate` path, not a direct write to `/sys/power/state`.
The previous tests forced `shutdown` mode. Kernel documentation recommends
testing `platform` mode because it executes additional firmware callbacks.
The normal systemd/platform test succeeded. Several factors changed, so this
does not isolate which change fixed automatic power-off.

A machine-local `hyprflux-hibernate-wifi.service` is installed as a required dependency
of systemd-hibernate. It removes only mt7921e before hibernate and reloads it after
the hibernate service finishes. Removal failure prevents the transition; no forced
module removal is used. Logs confirm successful unload/reload and reconnection
during the successful hardware test. Keep this dependency for normal hibernate.

Next, after the user saves work and approves, verify one real lid-close/open cycle:
automatic power-off, power-on, desktop, input, applications, both displays and Wi-Fi.
Keep suspend, hybrid sleep and suspend-then-hibernate disabled.
Save all work before testing. A forced power-off is **not** a
successful outcome, and an image must not be assumed complete merely because
the screen is dark.

## Diagnostic tool limitations

`utilities/sleep-lab.sh` is a privileged low-level diagnostic tool, not a desktop
sleep action. Its sysfs writes bypass logind locking, inhibitors, and normal
systemd hooks. A return from a real transition is labelled
`RESUMED_NEEDS_USER_CHECK`, not PASS. New kernel resume failures and driver errors
make the result degraded. Missing completion records are incomplete, not proof
that a hardware hang occurred. Existing historical log labels are unchanged.

## References

- https://docs.kernel.org/power/basic-pm-debugging.html
- https://docs.kernel.org/7.2/arch/x86/amd-debugging.html
- https://asus-linux.org/faq/general/enable-s3-suspend/
- https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate
- https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Preserve_video_memory_after_suspend
- https://www.gnu.org/software/grub/manual/grub/html_node/uki.html

Boot/configuration backups are under `~/dotfiles_backup/`; the NVIDIA late-load
backup was created under `/root/dotfiles_backup/`. The experimental configuration
does not establish working S3. The BIOS-specific ACPI override remains experimental;
removing it requires a separate backed-up UKI rebuild and boot test. No such test
is queued. Final-policy backups are under `hibernate-final-policy-20261108-115754`.
