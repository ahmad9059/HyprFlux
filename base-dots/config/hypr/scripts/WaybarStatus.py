#!/usr/bin/env python3
"""Waybar helpers. Stdout is reserved for module output, errors go to stderr."""
import sys

sys.dont_write_bytecode = True

from hyprflux.waybar import main

if __name__ == '__main__':
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(130)
    except (OSError, RuntimeError, ValueError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
