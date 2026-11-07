import os
from pathlib import Path
import re
import subprocess
import tempfile
import time

from .common import HYPR, notify, query, run


def screenshot(args):
    mode = args[0] if args else ''
    if mode not in ('--now', '--in5', '--in10', '--win', '--active', '--area', '--save-area'):
        raise RuntimeError('Usage: ScreenShot.sh --now|--in5|--in10|--active|--area|--save-area')
    geometry = None
    suffix = ''
    if mode in ('--area', '--save-area'):
        result = run(['slurp'], check=False, timeout=None)
        if result.returncode == 1:
            return
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or 'Area selection failed')
        if not result.stdout.strip():
            return
        geometry = result.stdout.strip()
    elif mode in ('--win', '--active'):
        window = query('activewindow')
        if not window or not window.get('size') or min(window['size']) <= 0:
            raise RuntimeError('No active window to capture')
        geometry = f'{window["at"][0]},{window["at"][1]} {window["size"][0]}x{window["size"][1]}'
        suffix = '_' + re.sub(r'[^\w.-]', '_', window.get('class', 'window'))[:80]
    elif mode in ('--in5', '--in10'):
        for seconds in range(5 if mode == '--in5' else 10, 0, -1):
            notify(f'Screenshot in {seconds} seconds')
            time.sleep(1)
    if geometry and not re.fullmatch(r'-?\d+,-?\d+ [1-9]\d*x[1-9]\d*', geometry):
        raise RuntimeError('Invalid screenshot geometry')
    try:
        result = run(['xdg-user-dir', 'PICTURES'], check=False)
        pictures = Path(result.stdout.strip()) if result.returncode == 0 and result.stdout.strip() else Path.home() / 'Pictures'
    except FileNotFoundError:
        pictures = Path.home() / 'Pictures'
    directory = pictures / 'Screenshots'
    directory.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.capture-', suffix='.png', dir=directory)
    os.close(fd)
    temporary = Path(name)
    final = directory / (time.strftime('Screenshot_%Y-%m-%d_%H-%M-%S') + suffix + '_' + temporary.stem.removeprefix('.capture-') + '.png')
    try:
        run(['grim', *(['-g', geometry] if geometry else []), str(temporary)])
        if not temporary.stat().st_size:
            raise RuntimeError('Screenshot capture was empty')
        os.replace(temporary, final)
    finally:
        temporary.unlink(missing_ok=True)
    with final.open('rb') as image:
        result = subprocess.run(['wl-copy', '--type', 'image/png'], stdin=image, capture_output=True, timeout=10)
    if result.returncode:
        raise RuntimeError('Screenshot saved to ' + str(final) + ', but copying to the clipboard failed')
    # Sound/notification failures must not invalidate an already-saved capture.
    try:
        run(['bash', str(HYPR / 'scripts/Sounds.sh'), '--screenshot'], check=False, timeout=3)
        result = run(['notify-send', '-t', '10000', '-A', 'open=Open', '-A', 'delete=Delete',
                      '-i', 'image-x-generic', 'Screenshot saved', str(final)], check=False, timeout=11)
        if result.stdout.strip() == 'open':
            subprocess.Popen(['swappy', '-f', str(final)], start_new_session=True)
        elif result.stdout.strip() == 'delete':
            final.unlink(missing_ok=True)
    except (OSError, subprocess.TimeoutExpired):
        pass
