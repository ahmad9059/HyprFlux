import json
from pathlib import Path
import re
import urllib.request

from .common import HYPR, notify


def version(name):
    match = re.fullmatch(r'v(\d+)\.(\d+)\.(\d+)', name)
    return tuple(map(int, match.groups())) if match else None


def check_update():
    """Check only: never stash, pull, clone, install or replace live settings."""
    local = max((v for p in HYPR.glob('v*') if (v := version(p.name))), default=None)
    if local is None:
        raise RuntimeError('Installed HyprFlux version marker is missing')
    request = urllib.request.Request(
        'https://api.github.com/repos/ahmad9059/HyprFlux/contents/.config/hypr?ref=main',
        headers={'Accept': 'application/vnd.github+json', 'User-Agent': 'HyprFlux-update-check'})
    with urllib.request.urlopen(request, timeout=15) as response:
        data = json.load(response)
    remote = max((v for entry in data if (v := version(entry.get('name', '')))), default=None)
    if remote is None:
        raise RuntimeError('Upstream did not return a HyprFlux version marker')
    if remote > local:
        notify('HyprFlux ' + '.'.join(map(str, remote)) + ' is available. Review the repository changes and back up your settings before selectively applying them. No files were changed.')
    else:
        notify('No newer HyprFlux version marker found. No files were changed.')
