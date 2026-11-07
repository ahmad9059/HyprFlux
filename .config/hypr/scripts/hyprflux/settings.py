import os
from pathlib import Path
import re
import shlex
import shutil
import tempfile

from .common import HYPR, detached, lock, menu, notify, run


def atomic_copy(source, target):
    fd, temporary = tempfile.mkstemp(prefix='.' + target.name, dir=target.parent)
    os.close(fd)
    try:
        shutil.copy2(source, temporary)
        os.replace(temporary, target)
    finally:
        Path(temporary).unlink(missing_ok=True)


def preset(kind):
    folder, target = ('animations', HYPR / 'UserConfigs/user-animations.lua') if kind == 'animation' else ('Monitor_Profiles', HYPR / 'monitors.lua')
    files = sorted((HYPR / folder).glob('*.lua'))
    if not files:
        raise RuntimeError('No Lua presets available in ' + folder)
    theme = HYPR.parent / 'rofi' / ('config-Animations.rasi' if kind == 'animation' else 'config-Monitors.rasi')
    index = menu([p.stem for p in files], 'Animation' if kind == 'animation' else 'Monitor profile', theme=theme)
    if index is None:
        return
    source = files[index]
    run(['luac', '-p', str(source)])
    with lock('preset-' + kind):
        fd, name = tempfile.mkstemp(prefix='.preset-backup-', dir=target.parent)
        os.close(fd)
        backup = Path(name)
        try:
            shutil.copy2(target, backup)
            atomic_copy(source, target)
            try:
                args = ['hyprctl', 'reload'] + (['config-only'] if kind == 'animation' else [])
                result = run(args)
                errors = run(['hyprctl', 'configerrors']).stdout.strip()
                if result.stdout.strip() != 'ok' or errors:
                    raise RuntimeError(errors or result.stdout.strip() or 'Preset reload failed')
            except Exception:
                atomic_copy(backup, target)
                run(['hyprctl', 'reload'], check=False)
                raise
        finally:
            backup.unlink(missing_ok=True)
    notify('Loaded preset: ' + source.stem)


def defaults():
    text = (HYPR / 'UserConfigs/user-defaults.lua').read_text()
    values = dict(re.findall(r'^\s*(term|files)\s*=\s*"([^"\n]+)"', text, flags=re.MULTILINE))
    return shlex.split(values.get('term', 'kitty')), shlex.split(os.environ.get('EDITOR') or 'nvim')


def launch(args):
    if not args or not shutil.which(args[0]):
        raise RuntimeError('Required program is not installed: ' + (args[0] if args else '(empty command)'))
    detached(args, 'quick-settings')


def quick_settings():
    editable = {
        'User Defaults': 'UserConfigs/user-defaults.lua',
        'ENV variables': 'UserConfigs/env-variables.lua',
        'Window Rules': 'UserConfigs/window-rules.lua',
        'User Keybinds': 'UserConfigs/user-keybinds.lua',
        'User Settings': 'UserConfigs/user-settings.lua',
        'Startup Apps': 'UserConfigs/startup-apps.lua',
        'Decorations': 'UserConfigs/user-decorations.lua',
        'Animations': 'UserConfigs/user-animations.lua',
        'Laptop Keybinds': 'UserConfigs/laptops.lua',
        'Default Keybinds': 'configs/keybinds.lua',
    }
    actions = {label: ['edit', str(HYPR / name)] for label, name in editable.items()}
    actions.update({
        'Configure Monitors / Workspaces': ['nwg-displays'],
        'GTK Settings': ['nwg-look'], 'Qt6 Settings': ['qt6ct'], 'Qt5 Settings': ['qt5ct'],
        'Choose Hyprland Animations': ['bash', str(HYPR / 'scripts/Animations.sh')],
        'Choose Monitor Profiles': ['bash', str(HYPR / 'scripts/MonitorProfiles.sh')],
        'Search for Keybinds': ['bash', str(HYPR / 'scripts/KeyBinds.sh')],
        'Toggle Game Mode': ['bash', str(HYPR / 'scripts/GameMode.sh')],
        'Check for HyprFlux Updates (read-only)': ['bash', str(HYPR / 'scripts/HyprFluxUpdate.sh')],
    })
    if shutil.which('kitty') and shutil.which('kitten'):
        actions['Choose Kitty Terminal Theme'] = ['kitty', '-e', 'kitten', 'themes']
    # Do not advertise a theme browser when no browser is installed.
    if shutil.which('rofi-theme-selector'):
        actions['Choose Rofi Theme'] = ['rofi-theme-selector']
    if shutil.which('gsettings'):
        actions['Toggle preferred light/dark appearance'] = ['appearance']
    labels = list(actions)
    selected = menu(labels, 'HyprFlux settings', theme=HYPR.parent / 'rofi/config-edit.rasi')
    if selected is None:
        return
    command = actions[labels[selected]]
    if command[0] == 'edit':
        terminal, editor = defaults()
        launch([*terminal, '-e', *editor, command[1]])
    elif command[0] == 'appearance':
        current = run(['gsettings', 'get', 'org.gnome.desktop.interface', 'color-scheme']).stdout
        preference = 'prefer-light' if 'prefer-dark' in current else 'prefer-dark'
        run(['gsettings', 'set', 'org.gnome.desktop.interface', 'color-scheme', preference])
        notify('Application appearance preference: ' + preference + ' (GTK theme unchanged)')
    else:
        launch(command)
