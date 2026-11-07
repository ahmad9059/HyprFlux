import os
from pathlib import Path
import shlex
import time

from .common import (evaluate, lock, lua, notify, owned_process, query, read_json,
                     run, runtime, shell_command, start_owned, stop_owned, write_json)

GAME = {
    'animations.enabled': False, 'decoration.shadow.enabled': False,
    'decoration.blur.enabled': False, 'decoration.rounding': 0,
    'decoration.active_opacity': 1.0, 'decoration.inactive_opacity': 1.0,
    'general.gaps_in': '0 0 0 0', 'general.gaps_out': '0 0 0 0', 'general.border_size': 0,
}


def option(name):
    import json
    data = json.loads(run(['hyprctl', '-j', 'getoption', name]).stdout)
    for kind in ('bool', 'int', 'float', 'css'):
        if kind in data:
            value = data[kind]
            if kind == 'css':
                edges = str(value).split()
                if len(edges) not in (1, 2, 4):
                    raise RuntimeError('Invalid CSS gap value')
                values = [int(edge) for edge in edges]
                if len(values) == 1:
                    values *= 4
                elif len(values) == 2:
                    values *= 2
                return ' '.join(map(str, values))
            return value
    raise RuntimeError('Unsupported option response: ' + name)


def config(values):
    result = {}
    for name, value in values.items():
        if name in ('general.gaps_in', 'general.gaps_out'):
            # JSON IPC renders CSS gaps as text; Lua config requires a typed table.
            edges = [int(edge) for edge in value.split()]
            if len(edges) != 4:
                raise RuntimeError('Expected four CSS gap edges')
            value = dict(zip(('top', 'right', 'bottom', 'left'), edges))
        target = result
        parts = name.split('.')
        for part in parts[:-1]:
            target = target.setdefault(part, {})
        target[parts[-1]] = value
    return 'hl.config(' + lua(result) + ')'


def game_mode():
    with lock('gamemode'):
        path = runtime() / 'gamemode.json'
        previous = read_json(path)
        current = {key: option(key) for key in GAME}
        if previous is not None:
            if current != GAME:
                path.unlink()
                notify('Game-mode state cleared: settings changed or configuration reloaded. No settings overwritten.')
                return
            if set(previous) != set(GAME) or any(type(previous[k]) is not type(current[k]) for k in GAME):
                raise RuntimeError('Invalid game-mode state; refusing to apply it')
            evaluate(config(previous))
            path.unlink()
            notify('Game mode disabled; previous settings restored')
        else:
            # Stage state before applying; remove it on failure. No wallpaper daemon changes.
            write_json(path, current)
            try:
                evaluate(config(GAME))
            except Exception:
                # hl.config may apply some keys before reporting another error.
                # Roll back the complete snapshot, not just the state marker.
                try:
                    evaluate(config(current))
                except Exception:
                    notify('Game-mode rollback failed; original values retained in ' + str(path), urgent=True)
                    raise
                path.unlink(missing_ok=True)
                raise
            notify('Game mode enabled')


def geometry(monitor):
    width, height = monitor['width'], monitor['height']
    if monitor.get('transform', 0) in (1, 3, 5, 7):
        width, height = height, width
    scale = monitor.get('scale', 1)
    if scale <= 0:
        raise RuntimeError('Invalid monitor scale')
    width, height = int(width / scale), int(height / scale)
    return (monitor['x'] + int(width * .175), monitor['y'] + int(height * .05),
            max(1, int(width * .65)), max(1, int(height * .5)))


def terminal_command(arguments, identity):
    if not arguments:
        raise RuntimeError('Usage: Dropterminal.sh <kitty|foot|ghostty|alacritty> [arguments]')
    args = shlex.split(arguments[0]) if len(arguments) == 1 else list(arguments)
    if not args:
        raise RuntimeError('A terminal command is required')
    executable = Path(args[0]).name
    flags = {
        'kitty': ['--class', identity, '--title', identity],
        'foot': ['--app-id', identity, '--title', identity],
        'ghostty': ['--class=' + identity, '--title=' + identity],
        'alacritty': ['--class', identity, '--title', identity],
    }
    if executable not in flags:
        raise RuntimeError('Dropdown supports kitty, foot, ghostty and alacritty; refusing an unidentified window')
    return [args[0], *flags[executable], *args[1:]]


def dropdown(arguments):
    with lock('dropdown'):
        identity = 'hyprflux-dropdown-' + runtime().name.removeprefix('hyprflux-')
        args = terminal_command([a for a in arguments if a != '-d'], identity)
        find = lambda: [c for c in query('clients') if c.get('class') == identity or c.get('initialClass') == identity]
        clients = find()
        if len(clients) > 1:
            raise RuntimeError('Multiple dropdown windows found; close the extra dropdown before toggling')
        monitor = next((m for m in query('monitors') if m.get('focused')), None)
        if not monitor:
            raise RuntimeError('No focused monitor')
        x, y, width, height = geometry(monitor)
        if not clients:
            evaluate('hl.exec_cmd(' + lua(shell_command(args)) + ',' + lua({
                'float': True, 'workspace': 'special:hyprflux-dropdown silent',
                'size': [width, height]}) + ')')
            deadline = time.monotonic() + 8
            while time.monotonic() < deadline:
                clients = find()
                if clients:
                    break
                time.sleep(.1)
            if len(clients) != 1:
                raise RuntimeError('Dropdown did not create a uniquely identified window within 8 seconds')
        client = clients[0]
        address = client['address']
        if not isinstance(address, str) or not address.startswith('0x'):
            raise RuntimeError('Invalid dropdown address')
        selector = 'address:' + address
        workspace = client.get('workspace', {}).get('name', '')
        if workspace != 'special:hyprflux-dropdown':
            evaluate('hl.dispatch(hl.dsp.window.move(' + lua({
                'window': selector, 'workspace': 'special:hyprflux-dropdown', 'follow': False}) + '))')
            return
        # Use the actual active workspace object, including an open special workspace.
        evaluate('local ws = hl.get_active_special_workspace() or hl.get_active_workspace(); '
                 'assert(ws, "No active workspace"); local target = ws.special and ws.name or ("name:" .. ws.name); '
                 'hl.dispatch(hl.dsp.window.float(' + lua({'window': selector, 'action': 'enable'}) + ')); '
                 'hl.dispatch(hl.dsp.window.move({window=' + lua(selector) + ',workspace=target,follow=false})); '
                 'hl.dispatch(hl.dsp.window.resize(' + lua({'window': selector, 'x': width, 'y': height}) + ')); '
                 'hl.dispatch(hl.dsp.window.move(' + lua({'window': selector, 'x': x, 'y': y}) + ')); '
                 'hl.dispatch(hl.dsp.focus(' + lua({'window': selector}) + '))')


def music(action, arguments):
    with lock('music'):
        if action == 'music-status':
            return 0 if owned_process('music') else 1
        stop_owned('music')
        if action == 'music-play':
            start_owned('music', ['mpv', *arguments])
    return 0
