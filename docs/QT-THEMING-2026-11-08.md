# Qt and Hyprtoolkit theme integration

## Two different toolkits

`hyprpolkitagent` 0.2 on the live system uses Hyprtoolkit 0.6, not Qt.
Its colors come from `~/.config/hypr/hyprtoolkit.conf`. The supplied palette
uses Catppuccin Mocha with blue/lavender accents; font and size defaults remain
unchanged. No PAM, polkit policy, permissions, or password handling is changed.

Qt Widgets uses Qt5ct/Qt6ct plus Kvantum. Both configuration files select
`kvantum`, with the existing Catppuccin Mocha palette and Papirus-Dark icons.
Kvantum's selected theme remains `catppuccin-mocha-blue`. Existing fonts,
scaling, and application-specific settings are preserved.

## Plugin selection

Set `QT_QPA_PLATFORMTHEME=qt5ct` once. The installed Qt6ct 0.11 plugin advertises
both `qt6ct` and `qt5ct`; each Qt version finds its own ABI-compatible plugin.
Two environment assignments do not select by Qt version: the last wins.
Do not substitute a semicolon-separated platform-theme list: upstream Qt does
not split this variable like it splits `QT_QPA_PLATFORM`.

Arch packages `kvantum` and `kvantum-qt5` provide the Qt6 and Qt5 engines
respectively. Both are installer dependencies. If the Qt5 engine is missing
on an existing system, install `kvantum-qt5` after any ongoing package operation
finishes; never delete an active package manager's database lock.

Kvantum styles Qt Widgets, not arbitrary Qt Quick/QML applications. The existing
`QT_QUICK_CONTROLS_STYLE=org.hyprland.style` is a separate setting and is unchanged.
Flatpak applications may need their own runtime theme extensions.

## Validation and activation

Run `python -m unittest discover -s tests -p test_qt_themes.py -v`.
Real probes compile against each installed Qt major version and run offscreen
with isolated configuration. They check the loaded platform plugin and Kvantum
engine, the underlying style beneath Qtct's proxy style, icons, and palette.
A separate Hyprlang probe validates the native palette's color keys. Missing
development libraries or engines produce explicit skips. CI installs both engines.

Back up live settings before applying changes. Patch the live environment file
instead of replacing it: its GPU block is machine-specific. Update only the Qt
style keys, not full live Qtct files. Reload Hyprland and reopen Qt applications;
already-running processes keep their original environment. Existing terminals
may also retain the old platform-theme variable until reopened.

The native agent may need one restart when adding its first toolkit config,
because it started without a configuration path to watch. Do not restart it
during an active authentication prompt. No authentication request is needed for
the automated theme tests, and tests must never enter a password.
