#!/bin/bash
# VirtIO/virgl can run Hyprland but fail Kitty's EGLConfig requirements.
# Limit the workaround to Kitty on a virtual DRM GPU; physical GPUs retain
# their normal renderer. Keep /usr/bin/kitty owned by its package.
set -euo pipefail
if [[ ! ${LIBGL_ALWAYS_SOFTWARE+x} ]]; then
    for driver in /sys/class/drm/card[0-9]*/device/driver; do
        [[ -L "$driver" ]] || continue
        case "$(basename -- "$(readlink -f -- "$driver")")" in
        virtio_gpu|virtio-pci)
            export LIBGL_ALWAYS_SOFTWARE=1
            # Do not leak the automatic workaround into shells/apps.
            exec /usr/bin/kitty --override 'env=LIBGL_ALWAYS_SOFTWARE' "$@"
            ;;
        esac
    done
fi
exec /usr/bin/kitty "$@"
