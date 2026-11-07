"""Safe, shared Rofi dialogs. Cancellation never changes clipboard or user data."""
import contextlib
import fcntl
import hashlib
import html
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

from .common import HYPR, detached, lock, notify, query, run, runtime


@contextlib.contextmanager
def session():
    """Only one managed dialog at a time; never kill somebody else's menu."""
    fd = os.open(runtime() / 'rofi.lock', os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'w') as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            yield False
            return
        yield True


def dialog(rows, prompt, *, theme=None, message=None, free_text=False, extra=None, custom_codes=()):
    args = ['rofi', '-dmenu', '-i', '-format', 's' if free_text else 'i', '-p', prompt]
    if not free_text:
        args.append('-no-custom')
    if theme:
        if not theme.is_file():
            raise RuntimeError('Rofi theme not found: ' + str(theme))
        args += ['-config', str(theme)]
    if message:
        args += ['-mesg', html.escape(message)]
    args += extra or []
    with session() as acquired:
        if not acquired:
            return None  # Leave the existing dialog alone.
        result = run(args, input='\n'.join(str(row).replace('\n', ' ').replace('\r', ' ') for row in rows) + '\n',
                     check=False, timeout=None)
    if result.returncode == 1:
        return None
    if result.returncode not in (0, *custom_codes):
        raise RuntimeError(result.stderr.strip() or f'Rofi failed (exit {result.returncode})')
    return result.returncode, result.stdout.rstrip('\n')


def index(text, size):
    try:
        value = int(text)
    except ValueError as error:
        raise RuntimeError('Invalid Rofi selection') from error
    if not 0 <= value < size:
        raise RuntimeError('Rofi selection outside the list')
    return value


def pick(rows, prompt, *, theme=None, message=None):
    if not rows:
        return None
    result = dialog(rows, prompt, theme=theme, message=message)
    return None if result is None else index(result[1], len(rows))


def clipboard_copy(data):
    if not data:
        raise RuntimeError('Nothing to copy; clipboard left unchanged')
    result = subprocess.run(['wl-copy'], input=data, stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL, timeout=10)
    if result.returncode:
        raise RuntimeError('Could not copy to the clipboard')


def emoji():
    rows = (HYPR / 'scripts/data/emoji.txt').read_text().splitlines()
    rows = [row for row in rows if row.strip()]
    selected = pick(rows, 'Emoji', theme=HYPR.parent / 'rofi/config-emoji.rasi',
                    message='Choose an emoji to copy. Escape keeps your clipboard unchanged.')
    if selected is not None:
        clipboard_copy(rows[selected].split(None, 1)[0].encode())


def clipboard():
    while True:
        rows = run(['cliphist', 'list']).stdout.splitlines()
        if not rows:
            notify('Clipboard history is empty')
            return
        selected = dialog(rows, 'Clipboard', theme=HYPR.parent / 'rofi/config-clipboard.rasi',
                          message='Ctrl+Delete: remove selected entry. Alt+Delete: clear history (with confirmation).',
                          extra=['-kb-custom-1', 'Control-Delete', '-kb-custom-2', 'Alt-Delete'], custom_codes=(10, 11))
        if selected is None:
            return
        code, value = selected
        if code == 11:
            confirm = pick(['Cancel', 'Delete all clipboard history'], 'Clear history?')
            if confirm == 1:
                run(['cliphist', 'wipe'])
            continue
        if code == 10 and not value:
            continue
        row = rows[index(value, len(rows))]
        if code == 10:
            run(['cliphist', 'delete'], input=row + '\n')
            continue
        decoded = subprocess.run(['cliphist', 'decode'], input=(row + '\n').encode(),
                                 capture_output=True, timeout=15)
        if decoded.returncode or not decoded.stdout:
            raise RuntimeError('Clipboard entry could not be decoded; current clipboard left unchanged')
        clipboard_copy(decoded.stdout)
        return


def launcher():
    with session() as acquired:
        if not acquired:
            return
        # Launched applications may inherit descriptors; do not capture pipes.
        result = subprocess.run(['rofi', '-show', 'drun', '-modi', 'drun,filebrowser,run,window'],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if result.returncode not in (0, 1):
        raise RuntimeError('Application launcher failed')


def calculator():
    previous = ''
    while True:
        selected = dialog([], 'Calculate', theme=HYPR.parent / 'rofi/config-calc.rasi',
                          message=previous or 'Type an expression. Successful results are copied.', free_text=True)
        if selected is None:
            return
        expression = selected[1].strip()
        if not expression:
            continue
        result = run(['qalc', '-t', '--', expression], check=False, timeout=15)
        value = result.stdout.strip()
        if result.returncode or not value or result.stderr.strip():
            previous = 'Calculation failed: ' + (result.stderr.strip() or value or 'no result')
            continue
        clipboard_copy(value.encode())
        previous = expression + ' = ' + value


def projects():
    folder = Path(os.environ.get('HYPRFLUX_PROJECTS_DIR', str(Path.home() / 'Documents/Projects'))).expanduser()
    if not folder.is_dir():
        raise RuntimeError('Projects directory not found: ' + str(folder))
    paths = sorted((p for p in folder.iterdir() if p.is_dir()), key=lambda p: p.name.casefold())
    selected = pick([p.name for p in paths], 'Project')
    if selected is None:
        return
    project = paths[selected].resolve(strict=True)
    tmuxifier = Path(os.environ.get('HYPRFLUX_TMUXIFIER_BIN', str(Path.home() / '.tmuxifier/bin/tmuxifier')))
    if not tmuxifier.is_file() or not os.access(tmuxifier, os.X_OK):
        raise RuntimeError('Tmuxifier is not installed: ' + str(tmuxifier))
    if not shutil.which('kitty'):
        raise RuntimeError('Kitty is required for the project launcher')
    # Folder names are environment values and argv, never a new shell program.
    detached(['kitty', '--title', 'tmuxifier: ' + project.name, '-e', str(tmuxifier), 'load-session', 'web-dev'],
             'project-launcher', env={**os.environ, 'PROJECT_DIR': str(project), 'SESSION_NAME': project.name})


def clone_repository():
    user = os.environ.get('HYPRFLUX_GITHUB_USER') or run(['gh', 'api', 'user', '-q', '.login']).stdout.strip()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]*', user):
        raise RuntimeError('GitHub username unavailable; run gh auth login first')
    entries = json.loads(run(['gh', 'repo', 'list', user, '--json', 'nameWithOwner', '-L', '300']).stdout)
    repos = [entry['nameWithOwner'] for entry in entries]
    folder = Path(os.environ.get('HYPRFLUX_PROJECTS_DIR', str(Path.home() / 'Documents/Projects'))).expanduser().resolve()
    labels = [('✓ ' if (folder / name.rsplit('/', 1)[-1]).exists() else '') + name for name in repos]
    selected = pick(labels, 'Clone GitHub repository')
    if selected is None:
        return
    full = repos[selected]
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+', full) or full.rsplit('/', 1)[1] in ('.', '..'):
        raise RuntimeError('Invalid repository name')
    target = folder / full.split('/')[1]
    folder.mkdir(parents=True, exist_ok=True)
    with lock('clone-' + hashlib.sha256(full.encode()).hexdigest()[:16]):
        if target.exists() or target.is_symlink():
            notify('Already present: ' + str(target))
            return
        notify('Cloning ' + full)
        run(['git', 'clone', 'https://github.com/' + full + '.git', str(target)], timeout=None)
        notify('Cloned ' + full)


def binding_rows(binds):
    modifiers = {1: 'SHIFT', 2: 'CAPS', 4: 'CTRL', 8: 'ALT', 16: 'MOD2', 32: 'MOD3', 64: 'SUPER', 128: 'MOD5', 256: 'NUM'}
    rows = []
    for bind in binds:
        mods = [name for bit, name in modifiers.items() if (bind.get('modmask') or 0) & bit]
        key = bind.get('key') or ('code:' + str(bind['keycode']) if bind.get('keycode') else '[keycode unavailable]')
        description = bind.get('description') or ('Lua callback' if bind.get('dispatcher') == '__lua' else (bind.get('dispatcher', '') + ' ' + bind.get('arg', '')).strip())
        rows.append(' + '.join([*mods, key]) + '\t' + description)
    return rows


def keybinds():
    rows = binding_rows(query('binds'))
    if not rows:
        raise RuntimeError('Hyprland returned no keybindings')
    pick(rows, 'Keybindings', theme=HYPR.parent / 'rofi/config-keybinds.rasi',
         message='Reference only. Some older Hyprland versions omit raw keycodes; unavailable values are labeled, never guessed.')


def music_menu():
    from .runtime import music
    selected = pick(['Play online stations', 'Play from Music directory', 'Shuffle local music', 'Stop RofiBeats'],
                    'Music source', theme=HYPR.parent / 'rofi/config-rofi-Beats-menu.rasi')
    if selected is None:
        return
    if selected == 3:
        music('music-stop', [])
        return
    if selected == 0:
        stations = json.loads((HYPR / 'scripts/data/radio-stations.json').read_text())
        names = sorted(stations)
        choice = pick(names, 'Station', theme=HYPR.parent / 'rofi/config-rofi-Beats.rasi')
        if choice is None:
            return
        args, label = ['--shuffle', '--vid=no', stations[names[choice]]], names[choice]
    else:
        folder = Path(os.environ.get('HYPRFLUX_MUSIC_DIR', str(Path.home() / 'Music'))).expanduser()
        if not folder.is_dir():
            raise RuntimeError('Music directory not found: ' + str(folder))
        paths = sorted(p for p in folder.rglob('*') if p.is_file() and p.suffix.lower() in {'.mp3', '.flac', '.wav', '.ogg', '.mp4'})
        if not paths:
            raise RuntimeError('No playable media files found')
        if selected == 1:
            choice = pick([str(p.relative_to(folder)) for p in paths], 'Music', theme=HYPR.parent / 'rofi/config-rofi-Beats.rasi')
            if choice is None:
                return
            args, label = ['--playlist-start=' + str(choice)], paths[choice].name
        else:
            args, label = ['--shuffle'], 'local music'
        args += ['--loop-playlist', '--vid=no', *map(str, paths)]
    music('music-play', args)  # Never announce success if process creation fails.
    notify('Opening music: ' + label)


def main(action):
    functions = {'launcher': launcher, 'emoji': emoji, 'clipboard': clipboard, 'calculator': calculator,
                 'projects': projects, 'clone': clone_repository, 'keybinds': keybinds, 'music': music_menu}
    if action not in functions:
        raise RuntimeError('Unknown Rofi action: ' + action)
    functions[action]()
