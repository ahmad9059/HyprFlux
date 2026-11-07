import hashlib
import os
from pathlib import Path
import random
import shutil
import subprocess
import tempfile
import time

from .common import (HYPR, detached, lock, menu, notify, query, read_json, run,
                     start_owned, stop_owned, write_json)

IMAGES = {'.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.tif', '.webp', '.pnm', '.tga', '.farbfeld'}
VIDEOS = {'.mp4', '.mkv', '.mov', '.webm'}


def collection(directory, *, videos=True):
    directory = Path(directory).expanduser()
    if not directory.is_dir():
        raise RuntimeError('Wallpaper directory not found: ' + str(directory))
    allowed = IMAGES | VIDEOS if videos else IMAGES
    paths = sorted((p for p in directory.rglob('*') if p.is_file() and p.suffix.lower() in allowed),
                   key=lambda p: str(p).casefold())
    if not paths:
        raise RuntimeError('No supported wallpapers in ' + str(directory))
    return paths


def focused():
    monitor = next((m['name'] for m in query('monitors') if m.get('focused')), None)
    if not monitor:
        raise RuntimeError('No focused monitor')
    return monitor


def ensure_awww():
    if run(['awww', 'query'], check=False, timeout=1).returncode == 0:
        return
    detached(['awww-daemon'], 'wallpaper-daemon')
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        if run(['awww', 'query'], check=False, timeout=1).returncode == 0:
            return
        time.sleep(.1)
    raise RuntimeError('Wallpaper daemon did not become ready within 5 seconds')


def state_path():
    return Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'hyprflux/wallpapers.json'


def remember(monitor, path):
    state = read_json(state_path(), {})
    state[monitor] = str(path.resolve())
    write_json(state_path(), state)


def preview(path):
    path = Path(path)
    if not path.is_file() or path.suffix.lower() not in IMAGES:
        raise RuntimeError('Current wallpaper is not a readable image')
    link = HYPR.parent / 'rofi/.current_wallpaper'
    link.parent.mkdir(parents=True, exist_ok=True)
    temporary = link.with_name('.wallpaper-link-' + str(os.getpid()))
    try:
        temporary.symlink_to(path.resolve())
        os.replace(temporary, link)
    finally:
        temporary.unlink(missing_ok=True)
    target = HYPR / 'wallpaper_effects/.wallpaper_current'
    target.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.wallpaper-', dir=target.parent)
    os.close(fd)
    try:
        shutil.copyfile(path, name)
        os.replace(name, target)
    finally:
        Path(name).unlink(missing_ok=True)


def sync_preview(monitor=None):
    monitor = monitor or focused()
    # Public query output, not an undocumented, version-dependent cache layout.
    text = run(['awww', 'query']).stdout
    for line in text.splitlines():
        if line.lstrip(': ').startswith(monitor + ': ') and 'currently displaying: image: ' in line:
            path = line.split('currently displaying: image: ', 1)[1]
            preview(Path(path))
            return
    raise RuntimeError('No image wallpaper reported for ' + monitor)


def apply(path, monitor, *, persist=True):
    path = Path(path).resolve(strict=True)
    if path.suffix.lower() in VIDEOS:
        stop_owned('video-' + hashlib.sha256(monitor.encode()).hexdigest()[:12])
        # Do not kill other applications' mpv/mpvpaper processes.
        process = start_owned('video-' + hashlib.sha256(monitor.encode()).hexdigest()[:12],
                              ['mpvpaper', monitor, '-o', 'load-scripts=no no-audio --loop', str(path)])
        # Readiness is not exposed by mpvpaper; catch an immediate launch failure.
        try:
            code = process.wait(timeout=.2)
        except subprocess.TimeoutExpired:
            code = None
        if code is not None:
            raise RuntimeError('Video wallpaper failed to start; inspect its runtime log')
    elif path.suffix.lower() in IMAGES:
        ensure_awww()
        run(['awww', 'img', '-o', monitor, str(path), '--transition-type', 'simple'])
        stop_owned('video-' + hashlib.sha256(monitor.encode()).hexdigest()[:12])
        preview(path)
    else:
        raise RuntimeError('Unsupported wallpaper type: ' + path.suffix)
    if persist:
        remember(monitor, path)


def select(directory, *, random_only=False):
    paths = collection(directory, videos=not random_only)
    if random_only:
        selected = random.choice(paths)
    else:
        labels = ['Random wallpaper']
        for path in paths:
            label = str(path.relative_to(directory)).replace('\n', ' ').replace('\r', ' ')
            labels.append(label + (' [video]' if path.suffix.lower() in VIDEOS else '\0icon\x1f' + str(path)))
        index = menu(labels, 'Wallpaper', theme=HYPR.parent / 'rofi/config-wallpaper.rasi')
        if index is None:
            return
        selected = random.choice(paths) if index == 0 else paths[index - 1]
    with lock('wallpaper'):
        apply(selected, focused())


def restore():
    with lock('wallpaper'):
        state = read_json(state_path(), {})
        monitors = query('monitors')
        ensure_awww()  # Also restores awww's own cache for pre-migration users.
        failures = []
        for monitor in monitors:
            path = state.get(monitor['name'])
            if path:
                try:
                    apply(Path(path), monitor['name'], persist=False)
                except (OSError, RuntimeError) as error:
                    failures.append(str(error))
        if failures:
            raise RuntimeError('; '.join(failures))
        if not state:
            try:
                sync_preview()
            except RuntimeError:
                pass  # No image has been selected on a fresh installation yet.


EFFECTS = {
    'Black & White': ['-colorspace', 'gray', '-sigmoidal-contrast', '10,40%'],
    'Blurred': ['-blur', '0x10'], 'Charcoal': ['-charcoal', '0x5'],
    'Edge Detect': ['-edge', '1'], 'Emboss': ['-emboss', '0x5'],
    'Frame Raised': ['+raise', '150'], 'Frame Sunk': ['-raise', '150'],
    'Negate': ['-negate'], 'Oil Paint': ['-paint', '4'],
    'Posterize': ['-posterize', '4'], 'Polaroid': ['-polaroid', '0'],
    'Sepia Tone': ['-sepia-tone', '65%'], 'Solarize': ['-solarize', '80%'],
    'Sharpen': ['-sharpen', '0x5'], 'Vignette': ['-vignette', '0x3'],
    'Vignette-black': ['-background', 'black', '-vignette', '0x3'],
    'Zoomed': ['-gravity', 'Center', '-extent', '1:1'],
}


def effects():
    names = ['No Effects', *sorted(EFFECTS)]
    selected = menu(names, 'Wallpaper effect', theme=HYPR.parent / 'rofi/config-wallpaper-effect.rasi')
    if selected is None:
        return
    with lock('wallpaper'):
        monitor = focused()
        source = read_json(state_path(), {}).get(monitor)
        if not source:
            sync_preview(monitor)
            source = str((HYPR.parent / 'rofi/.current_wallpaper').resolve())
            remember(monitor, Path(source))
        source = Path(source)
        if not source.is_file() or source.suffix.lower() not in IMAGES:
            raise RuntimeError('Select an image wallpaper before applying effects')
        if selected == 0:
            apply(source, monitor, persist=False)
        else:
            cache = Path(os.environ.get('XDG_CACHE_HOME', str(Path.home() / '.cache'))) / 'hyprflux/effects'
            cache.mkdir(parents=True, exist_ok=True)
            fd, name = tempfile.mkstemp(suffix='.png', dir=cache)
            os.close(fd)
            output = Path(name)
            try:
                run(['magick', str(source), *EFFECTS[names[selected]], str(output)], timeout=120)
                if not output.stat().st_size:
                    raise RuntimeError('ImageMagick produced an empty wallpaper')
                # Stable path avoids accumulating a new cache file on each click.
                final = cache / (hashlib.sha256(monitor.encode()).hexdigest()[:16] + '.png')
                os.replace(output, final)
                apply(final, monitor, persist=False)
            finally:
                output.unlink(missing_ok=True)
        notify('Wallpaper effect applied: ' + names[selected])


def auto(directory):
    interval = int(os.environ.get('HYPRFLUX_WALLPAPER_INTERVAL', '1800'))
    if interval < 1:
        raise RuntimeError('Wallpaper interval must be positive')
    with lock('wallpaper-auto'):
        while True:
            try:
                select(directory, random_only=True)
            except (RuntimeError, OSError) as error:
                notify(str(error), urgent=True)
                raise  # Never silently wait 30 minutes after a failed operation.
            time.sleep(interval)


def main(action, args):
    directory = Path(args[0] if args else os.environ.get('HYPRFLUX_WALLPAPER_DIR', str(Path.home() / 'Pictures/wallpapers'))).expanduser()
    if action == 'wallpaper-select':
        select(directory)
    elif action == 'wallpaper-random':
        select(directory, random_only=True)
    elif action == 'wallpaper-sync':
        sync_preview()
    elif action == 'wallpaper-restore':
        restore()
    elif action == 'wallpaper-effects':
        effects()
    elif action == 'wallpaper-auto':
        auto(directory)
    else:
        raise RuntimeError('Unknown wallpaper action')
    return 0
