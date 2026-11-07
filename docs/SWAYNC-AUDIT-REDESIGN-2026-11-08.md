# SwayNC audit and redesign

Validated against the installed SwayNC **0.12.6** schema, GTK4 CSS parser and
upstream configuration/CSS documentation. Source: `.config/swaync/`; mirrored
under `base-dots/config/swaync/` and selectively deployed to `~/.config/swaync/`.

## Findings and repairs

- Critical notifications previously expired after three seconds. The default
  critical timeout is now **0** (persistent until dismissed); normal/low defaults
  are 8/4 seconds. Applications can still supply their own explicit timeouts.
- Removed deprecated JSON icon/album-art sizes and unsupported MPRIS
  `image-radius`. GTK4 CSS variables now control notification and media icons.
- Removed inactive label/backlight widget configuration. Every configured
  widget is used; MPRIS hides automatically without useful player metadata.
- Replaced the legacy `hyprctl dispatch exit` action with a power menu, avoiding
  an immediate unconfirmed logout. Network opens the network interface rather
  than silently toggling Wi-Fi while calling it airplane mode.
- Replaced unlabeled, wrapping quick-action icons with two complete rows of
  three labeled buttons: Lock, Power, Settings, Network, Mute, Mic off.
- Audio toggles set the requested mute state rather than blindly toggling;
  read-only status queries refresh them whenever the panel opens. Opening the
  panel does not change audio or microphone state.
- Removed tiny inherited action text, global bold body typography and hidden
  DND text. Restored readable hierarchy, spacing, useful hover states and
  visible keyboard focus. At the user's request the panel scrollbar is hidden;
  mouse-wheel and touchpad scrolling remain available.
- Added a volume slider with an optional per-app section. Media uses compact
  cover art and a consistent opaque surface instead of a blurred image wash.
- Kept the exact original **`#0e0e16`** background and the generated color block;
  color-generator idempotence remains tested.

## Requested refinements

- Panel width: **420 → 378px** (10% narrower).
- Panel height: **1100px**, approximately 20% taller than the displayed panel.
  Notification history expands and scrolls within that space; SwayNC's normal
  compositor-size limit remains enabled for smaller displays.
- Popup width remains 400px; changing panel width does not unnecessarily shrink
  floating notifications.
- Open/Delete and other action buttons use the same dark background with a
  subtle outline and neutral hover, not the purple `#160b2b`-like fill. Both the
  action container and its actual nested GTK button are styled explicitly.

## Related screenshot regression

The live popup check exposed a timeout in the recently refactored screenshot
helper. `wl-copy` forks a clipboard owner; capturing its stdout/stderr can keep
`communicate()` waiting on inherited pipes after the initial process exits.
The helper now redirects those streams to `DEVNULL`, retaining its exit-status
and timeout checks. A regression assertion prevents captured pipes from being
reintroduced. The previous error alert was left in the user's notification
history rather than deleting unrelated alerts.

## Validation and deployment

- Full configuration passes the real installed JSON schema, including widget
  properties. CSS loads through GTK4 with **zero parser messages**.
- **72 tests passed** in an isolated Arch validation image with Hyprland 0.57.1,
  SwayNC 0.12.6, GTK4 and schema validation dependencies. The host validation
  environment passes 69 with three private-source parser checks skipped.
- Test coverage includes command syntax, full quick-action rows, state-aware
  audio commands, read-only status refresh, deprecated-field rejection, exact
  background, neutral nested action buttons and mirror parity.
- Both panel and popups were inspected in the real Wayland session. A focused
  notification retains its critical color instead of becoming purple.
- Config/CSS were reloaded without restarting SwayNC. The daemon PID, DND state
  and existing history were preserved. Only explicitly recorded preview
  notification IDs were removed; Clear All was never invoked.
- No lock, power, network change, audio mute or microphone change was triggered
  during validation. Action mutations use isolated command mocks.
- CI now installs SwayNC, GTK Python bindings and the JSON-schema validator so
  those validations do not silently skip there. No host packages were installed.

Initial verified backup:
`~/dotfiles_backup/swaync-before-redesign-20261108-033032-518542/`

The pre-resize design is also backed up under the timestamped
`~/dotfiles_backup/swaync-before-resize-*/` directory. The original background
is unchanged, and existing personal Hyprland/Waybar settings were not replaced.

References:
- [SwayNC configuration](https://github.com/ErikReider/SwayNotificationCenter/blob/main/_autodocs/configuration.md)
- [SwayNC widgets](https://github.com/ErikReider/SwayNotificationCenter/blob/main/_autodocs/api-reference/widgets.md)
- Local `/etc/xdg/swaync/configSchema.json` and `/etc/xdg/swaync/style.css`.
