#!/usr/bin/env python3
"""Entrypoint for shared HyprFlux actions; never runs installers implicitly."""
import sys

sys.dont_write_bytecode = True

from hyprflux.common import notify


def main(arguments):
    if not arguments:
        raise ValueError('A desktop action is required')
    action, *args = arguments
    if action.startswith('rofi-'):
        from hyprflux import rofi
        rofi.main(action.removeprefix('rofi-'))
    elif action in ('game-mode', 'dropdown') or action.startswith('music-'):
        from hyprflux import runtime
        if action == 'game-mode':
            runtime.game_mode()
        elif action == 'dropdown':
            runtime.dropdown(args)
        else:
            return runtime.music(action, args)
    elif action == 'touchpad':
        from hyprflux.devices import touchpad
        touchpad()
    elif action.startswith('wallpaper-'):
        from hyprflux import wallpaper
        return wallpaper.main(action, args)
    elif action == 'screenshot':
        from hyprflux.screenshot import screenshot
        screenshot(args)
    elif action in ('animation-preset', 'monitor-preset', 'quick-settings'):
        from hyprflux import settings
        if action == 'quick-settings':
            settings.quick_settings()
        else:
            settings.preset('animation' if action == 'animation-preset' else 'monitor')
    elif action == 'check-update':
        from hyprflux.update import check_update
        check_update()
    else:
        raise ValueError('Unknown desktop action: ' + action)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as error:
        print(str(error), file=sys.stderr)
        notify(str(error), urgent=True)
        sys.exit(1)
