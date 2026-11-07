import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

HYPR = Path(__file__).resolve().parents[2]


def run(args, *, check=True, timeout=20, input=None):
    result = subprocess.run(args, input=input, text=True, capture_output=True, timeout=timeout)
    if check and result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or f'{args[0]} failed')
    return result


def query(command):
    return json.loads(run(['hyprctl', '-j', command]).stdout)


def lua(value):
    """Serialize data, never interpolate it as Lua source or shell code."""
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        if not float('-inf') < value < float('inf'):
            raise ValueError('Non-finite Lua number')
        return repr(value)
    if isinstance(value, (str, Path)):
        # Fixed-width decimal escapes also support NUL and non-ASCII paths.
        return '"' + ''.join(f'\\{b:03d}' for b in str(value).encode()) + '"'
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items()) + '}'
    if isinstance(value, (tuple, list)):
        return '{' + ','.join(map(lua, value)) + '}'
    raise TypeError(type(value).__name__)


def evaluate(code):
    result = run(['hyprctl', 'eval', code])
    if result.stdout.strip() != 'ok':
        raise RuntimeError(result.stdout.strip() or 'Hyprland rejected the action')


def notify(message, *, urgent=False):
    try:
        run(['notify-send', '-a', 'HyprFlux', '-u', 'critical' if urgent else 'low',
             'HyprFlux', message], check=False, timeout=3)
    except (OSError, subprocess.TimeoutExpired):
        pass


def runtime():
    base = Path(os.environ.get('XDG_RUNTIME_DIR', '/nonexistent'))
    if not base.is_dir() or base.is_symlink() or base.stat().st_uid != os.getuid():
        raise RuntimeError('A private XDG_RUNTIME_DIR is required')
    if base.stat().st_mode & 0o077:
        raise RuntimeError('XDG_RUNTIME_DIR must not be accessible to other users')
    session = hashlib.sha256(os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', 'default').encode()).hexdigest()[:16]
    path = base / ('hyprflux-' + session)
    path.mkdir(mode=0o700, exist_ok=True)
    if path.is_symlink() or path.stat().st_uid != os.getuid() or path.stat().st_mode & 0o077:
        raise RuntimeError('Unsafe HyprFlux runtime directory')
    return path


@contextlib.contextmanager
def lock(name):
    fd = os.open(runtime() / (name + '.lock'), os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'w') as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        yield


def read_json(path, default=None):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return default


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.' + path.name, dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            json.dump(value, stream)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def menu(labels, prompt, *, theme=None):
    """Return an index, never resolve a filename from an ambiguous basename."""
    from .rofi import pick
    return pick(labels, prompt, theme=theme)


def detached(args, name, *, env=None):
    with (runtime() / (name + '.log')).open('ab') as log:
        return subprocess.Popen(args, stdout=log, stderr=log, start_new_session=True, env=env)


def process_identity(pid):
    try:
        path = Path('/proc') / str(pid)
        if path.stat().st_uid != os.getuid():
            return None
        stat = (path / 'stat').read_text().rsplit(')', 1)[1].split()
        if stat[0] == 'Z':
            return None
        return stat[19]  # starttime, field 22; stable across PID reuse
    except (FileNotFoundError, ProcessLookupError):
        return None


def owned_process(name):
    state = read_json(runtime() / (name + '.json'), {})
    pid = state.get('pid', 0)
    return pid if pid > 1 and state.get('start') == process_identity(pid) and state.get('start') else None


def start_owned(name, args):
    process = detached(args, name)
    identity = process_identity(process.pid)
    if not identity:
        raise RuntimeError(f'{args[0]} exited during startup; see {runtime() / (name + ".log")}')
    write_json(runtime() / (name + '.json'), {'pid': process.pid, 'start': identity})
    return process


def stop_owned(name):
    import signal
    pid = owned_process(name)
    if pid:
        try:
            if os.getpgid(pid) != pid:
                raise RuntimeError('Refusing to stop a process group not owned by this action')
            os.killpg(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    (runtime() / (name + '.json')).unlink(missing_ok=True)


def shell_command(args):
    return shlex.join([str(arg) for arg in args])
