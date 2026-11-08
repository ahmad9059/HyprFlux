"""Small, testable adapters for Waybar's JSON protocol and application actions."""
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time

from .common import HYPR, lock, notify, query, runtime, write_json


def payload(text='', tooltip='', state='idle'):
    return {'text': text, 'tooltip': tooltip, 'alt': state, 'class': state}


def update_status():
    """checkupdates exit 2 means no updates; failures must never look up-to-date."""
    if not shutil.which('checkupdates'):
        return payload('', 'Update checks require pacman-contrib (checkupdates).', 'unavailable')
    try:
        result = subprocess.run(['checkupdates'], capture_output=True, text=True, timeout=90)
    except (OSError, subprocess.TimeoutExpired) as error:
        return payload('', 'Update check failed: ' + str(error), 'error')
    if result.returncode not in (0, 2):
        return payload('', 'Update check failed. Right click to retry.\n' + result.stderr.strip()[:400], 'error')
    packages = result.stdout.strip().splitlines() if result.returncode == 0 else []
    hint = '\nLeft: update system · Right: refresh check\nOfficial repositories only; AUR updates are not counted.'
    if not packages:
        return payload('󰄬', 'Official repository packages are up to date.' + hint, 'updated')
    listing = '\n'.join(packages[:20])
    if len(packages) > 20:
        listing += f'\n… and {len(packages) - 20} more'
    return payload(f' {len(packages)}', listing + hint, 'updates')


def updates():
    # All monitors share one short-lived result and one checkupdates transaction.
    with lock('waybar-updates'):
        cache = runtime() / 'waybar-updates.json'
        try:
            saved = json.loads(cache.read_text())
            age = time.time() - saved['time']
            if 0 <= age < 300:
                return saved['payload']
        except (OSError, ValueError, KeyError, TypeError):
            pass
        value = update_status()
        write_json(cache, {'time': time.time(), 'payload': value})
        return value


def refresh_updates():
    with lock('waybar-updates'):
        (runtime() / 'waybar-updates.json').unlink(missing_ok=True)
    subprocess.run(['pkill', '-u', str(os.getuid()), '-RTMIN+8', '-x', 'waybar'], check=False)


def media():
    # Legacy custom/playerctl compatibility. Native mpris is the default.
    # Never splice metadata into a JSON template or a shell program.
    try:
        fields = []
        for field in ('artist', 'title'):
            result = subprocess.run(['playerctl', 'metadata', field], capture_output=True, text=True, timeout=3)
            fields.append(result.stdout.strip() if result.returncode == 0 else '')
        status = subprocess.run(['playerctl', 'status'], capture_output=True, text=True, timeout=3)
        if status.returncode:
            return payload()
        text = ' — '.join(field for field in fields if field)
        return payload(text, text, status.stdout.strip().lower())
    except (OSError, subprocess.TimeoutExpired):
        return payload()


def keyboard():
    keyboards = query('devices').get('keyboards', [])
    device = next((item for item in keyboards if item.get('main')), None)
    if device is None:
        device = next(iter(keyboards), {})
    value = device.get('active_keymap', '')
    return payload(value, 'Active keyboard layout: ' + value)


def defaults():
    try:
        text = (HYPR / 'UserConfigs/user-defaults.lua').read_text()
    except FileNotFoundError:
        text = ''
    # Only literal string defaults are supported. Do not execute user Lua.
    values = dict(re.findall(r'^\s*(term|files)\s*=\s*"([^"\n]+)"', text, re.MULTILINE))
    return {key: shlex.split(values.get(key, fallback))
            for key, fallback in (('term', 'kitty'), ('files', 'thunar'))}


def launch(action):
    apps = defaults()
    if action == '--term':
        args = apps['term']
    elif action == '--files':
        args = apps['files']
    elif action == '--browser':
        args = ['xdg-open', 'https://www.google.com']
    elif action in ('--btop', '--nvtop', '--nmtui'):
        command = action[2:]
        terminal = apps['term']
        if not terminal:
            raise RuntimeError('Set a terminal in UserConfigs/user-defaults.lua')
        if not shutil.which(command):
            raise RuntimeError(command + ' is not installed')
        if Path(terminal[0]).name not in ('kitty', 'foot', 'footclient', 'alacritty', 'ghostty'):
            raise RuntimeError('Terminal tool launching supports kitty, foot, alacritty and ghostty')
        args = [*terminal, '--title', command, '-e', command]
    else:
        raise ValueError('Usage: WaybarScripts.sh --term|--files|--browser|--btop|--nvtop|--nmtui')
    if not args or not shutil.which(args[0]):
        raise RuntimeError('Configured application is not installed: ' + shlex.join(args))
    return subprocess.call(args)


def cava():
    """Each instance owns one child; cancellation never kills another bar/player."""
    if not shutil.which('cava'):
        raise RuntimeError('Cava is not installed')
    with tempfile.TemporaryDirectory(prefix='waybar-cava-', dir=runtime()) as directory:
        config = Path(directory) / 'config'
        config.write_text('''[general]
framerate = 15
bars = 10
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
''')
        process = subprocess.Popen(['cava', '-p', str(config)], stdout=subprocess.PIPE,
                                   text=True, start_new_session=True)
        def terminate(_signum, _frame):
            raise KeyboardInterrupt
        previous = {sig: signal.signal(sig, terminate) for sig in (signal.SIGTERM, signal.SIGINT)}
        try:
            for line in process.stdout:
                try:
                    bars = ''.join('▁▂▃▄▅▆▇█'[max(0, min(7, int(value)))]
                                   for value in line.strip().split(';') if value)
                except ValueError:
                    continue
                print(bars, flush=True)
            return process.wait()
        except BrokenPipeError:
            return 0
        finally:
            for sig, handler in previous.items():
                signal.signal(sig, handler)
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            process.stdout.close()


def main(arguments):
    if not arguments:
        raise ValueError('A Waybar action is required')
    action, *args = arguments
    if action == 'launch' and len(args) == 1:
        try:
            return launch(args[0])
        except (OSError, RuntimeError, ValueError) as error:
            notify(str(error), urgent=True)
            raise
    if args:
        raise ValueError('Unexpected Waybar action arguments')
    if action == 'cava':
        return cava()
    if action == 'refresh-updates':
        refresh_updates()
        return 0
    functions = {'updates': updates, 'media': media, 'keyboard': keyboard}
    if action not in functions:
        raise ValueError('Unknown Waybar action: ' + action)
    try:
        value = functions[action]()
    except (OSError, RuntimeError, ValueError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr)
        value = payload('', str(error), 'error')
    print(json.dumps(value, ensure_ascii=False), flush=True)
    return 0
