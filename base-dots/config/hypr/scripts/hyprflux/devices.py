import os

from .common import evaluate, lock, lua, notify, query


def touchpad():
    mice = query('devices').get('mice', [])
    override = os.environ.get('HYPRFLUX_TOUCHPAD')
    names = [m['name'] for m in mice if m['name'] == override] if override else [m['name'] for m in mice if 'touchpad' in m['name'].lower()]
    if not names:
        raise RuntimeError('No touchpad found; set HYPRFLUX_TOUCHPAD to its exact hyprctl device name')
    with lock('touchpad'):
        # Lua globals reset with the config, just like dynamic hl.device overrides.
        # This script owns these overrides; do not persist a stale filesystem flag.
        evaluate('local names = ' + lua(names) + '; '
                 '_G.hyprflux_touchpads = _G.hyprflux_touchpads or {}; '
                 'for _, name in ipairs(names) do '
                 'local enabled = _G.hyprflux_touchpads[name] ~= false; '
                 'hl.device({name=name, enabled=not enabled}); '
                 '_G.hyprflux_touchpads[name] = not enabled; end')
        notify('Touchpad state toggled')
