"""Desktop-source regression tests. Never install packages on the host."""
import configparser
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DesktopTests(unittest.TestCase):
    def test_foot_config_and_base_dots_match(self):
        for name in ('foot.ini', 'colors.ini'):
            self.assertEqual((ROOT / '.config/foot' / name).read_bytes(),
                             (ROOT / 'base-dots/config/foot' / name).read_bytes())
        main = configparser.ConfigParser(interpolation=None)
        main.read(ROOT / '.config/foot/foot.ini')
        self.assertEqual(main['main']['include'], '~/.config/foot/colors.ini')
        self.assertTrue(main.getboolean('colors-dark', 'blur'))
        self.assertEqual(main.getfloat('colors-dark', 'alpha'), .80)
        colors = configparser.ConfigParser(interpolation=None)
        colors.read(ROOT / '.config/foot/colors.ini')
        for index in range(8):
            self.assertRegex(colors['colors-dark'][f'bright{index}'], r'^[0-9a-f]{6}$')
            self.assertRegex(colors['colors-dark'][f'regular{index}'], r'^[0-9a-f]{6}$')

    def test_color_generator_preserves_valid_foot_output(self):
        outputs = ('hypr/hyprflux-colors.lua', 'rofi/hyprflux-colors.rasi',
                   'waybar/hyprflux-colors.css', 'kitty/kitty-colors.conf',
                   'foot/colors.ini', 'swaync/style.css', 'wlogout/style.css')
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for name in (*outputs, 'hypr/hyprflux-colors/hyprflux-colors.conf'):
                path = root / '.config' / name
                path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / '.config' / name, path)
            (root / 'utilities').mkdir()
            shutil.copyfile(ROOT / 'utilities/sync-colors.sh', root / 'utilities/sync-colors.sh')
            for _ in range(2):
                subprocess.run(['bash', str(root / 'utilities/sync-colors.sh')], check=True,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                for name in outputs:
                    self.assertEqual((root / '.config' / name).read_bytes(),
                                     (ROOT / '.config' / name).read_bytes(), name)

    @unittest.skipUnless(shutil.which('foot'), 'Foot is installed by config-check CI')
    def test_real_foot_checker(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            (home / '.config').mkdir()
            shutil.copytree(ROOT / '.config/foot', home / '.config/foot')
            result = subprocess.run(['foot', '--check-config'], text=True, capture_output=True,
                                    env={**os.environ, 'HOME': str(home),
                                         'XDG_CONFIG_HOME': str(home / '.config')})
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_kitty_virtio_only_and_preserves_overrides_and_arguments(self):
        source = (ROOT / 'utilities/kitty-launcher.sh').read_text()
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            driver = root / 'card0/device/driver'
            driver.parent.mkdir(parents=True)
            binary = root / 'kitty'
            binary.write_text('#!/bin/bash\nprintf "SOFTWARE=%s;" "${LIBGL_ALWAYS_SOFTWARE-unset}"; printf "<%s>" "$@"\n')
            binary.chmod(0o755)
            script = root / 'launch'
            script.write_text(source.replace('/sys/class/drm', str(root)).replace('/usr/bin/kitty', str(binary)))
            env = {key: value for key, value in os.environ.items() if key != 'LIBGL_ALWAYS_SOFTWARE'}
            def run(environment):
                return subprocess.check_output(['bash', str(script), 'argument with spaces'], env=environment, text=True)
            for name in ('virtio_gpu', 'virtio-pci', 'amdgpu', 'i915', 'nvidia'):
                target = root / name
                target.mkdir()
                driver.symlink_to(target)
                expected = 'SOFTWARE=1;<--override><env=LIBGL_ALWAYS_SOFTWARE>' if name.startswith('virtio') else 'SOFTWARE=unset;'
                self.assertEqual(run(env), expected + '<argument with spaces>')
                self.assertEqual(run({**env, 'LIBGL_ALWAYS_SOFTWARE': '0'}), 'SOFTWARE=0;<argument with spaces>')
                driver.unlink()

    def make_icons(self, root):
        for size in ('22x22', '24x24', '32x32', '48x48', '64x64'):
            places = root / size / 'places'
            places.mkdir(parents=True)
            for name in ('folder-cyan', 'folder-cyan-documents', 'user-cyan-home'):
                (places / (name + '.svg')).write_text('<svg/>')
                (places / (name.replace('-cyan', '') + '.svg')).symlink_to('blue.svg')

    def test_cyan_links_idempotent_and_fail_if_variants_missing(self):
        with tempfile.TemporaryDirectory() as temp:
            theme = Path(temp) / 'Papirus'
            self.make_icons(theme)
            script = ROOT / 'utilities/papirus-cyan.sh'
            for _ in range(2):
                subprocess.run(['bash', str(script), str(theme)], check=True, stdout=subprocess.PIPE)
            for places in theme.glob('*/places'):
                self.assertEqual((places / 'folder.svg').readlink().name, 'folder-cyan.svg')
                self.assertEqual((places / 'user-home.svg').readlink().name, 'user-cyan-home.svg')
            result = subprocess.run(['bash', str(script), str(theme / 'missing')], capture_output=True)
            self.assertNotEqual(result.returncode, 0)

    def run_module(self, name, temp, fail_pacman=False):
        home = Path(temp) / 'home'
        home.mkdir(exist_ok=True)
        theme = Path(temp) / 'icons'
        if not theme.exists():
            self.make_icons(theme)
        script = r'''
            set -euo pipefail
            should_skip() { return 1; }
            log_action() { :; }; log_ok() { :; }; log_warn() { :; }; log_error() { echo "$*"; }
            gtk-update-icon-cache() { :; }; export -f gtk-update-icon-cache
            sudo() {
                printf '%s\n' "$*" >> "$SANDBOX/commands"
                case "$1" in
                    pacman) [[ "$FAIL_PACMAN" != yes ]] ;;
                    install) shift; local dest="${@: -1}"; set -- "${@:1:$#-1}"; command install "$@" "$SANDBOX/root$dest" ;;
                    /usr/local/libexec/hyprflux-papirus-cyan) bash "$SANDBOX/root/usr/local/libexec/hyprflux-papirus-cyan" "$SANDBOX/icons" ;;
                    *) command "$@" ;;
                esac
            }
            source "$MODULE"
        '''
        env = {**os.environ, 'HOME': str(home), 'SANDBOX': temp, 'REPO_DIR': str(ROOT),
               'MODULE': str(ROOT / 'modules' / name), 'FAIL_PACMAN': 'yes' if fail_pacman else 'no',
               'SDDM_THEME_NAME': 'HyprFlux-sddm-theme', 'SDDM_THEME_SOURCE': str(Path(temp) / 'source-theme'),
               'SDDM_THEME_DEST': str(Path(temp) / 'installed-theme'), 'SDDM_CONF': str(Path(temp) / 'sddm.conf')}
        return subprocess.run(['bash', '-c', script], env=env, text=True, capture_output=True)

    def test_theme_module_installs_shared_helper_and_upgrade_hook(self):
        # Avoid copying the real theme/cursor assets into the test home.
        source = (ROOT / 'modules/04-themes.sh').read_text()
        start = source.index('# ====== Icons (Papirus)')
        end = source.index('# ====== Cursor theme')
        with tempfile.TemporaryDirectory() as temp:
            module = Path(temp) / 'icons-module.sh'
            module.write_text(source[start:end])
            result = self.run_module(str(module), temp)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((Path(temp) / 'root/etc/pacman.d/hooks/hyprflux-papirus-cyan.hook').is_file())
            commands = (Path(temp) / 'commands').read_text()
            self.assertNotIn('papirus-folders', commands)
            self.assertEqual((Path(temp) / 'icons/48x48/places/folder.svg').readlink().name, 'folder-cyan.svg')
            result = self.run_module(str(module), temp, fail_pacman=True)
            self.assertNotEqual(result.returncode, 0)

    def test_sddm_dependencies_and_repeat_install(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'source-theme').mkdir()
            (root / 'source-theme/Main.qml').write_text('import Qt5Compat.GraphicalEffects\n')
            for _ in range(2):
                result = self.run_module('06-sddm.sh', temp)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue((root / 'installed-theme/Main.qml').is_file())
            self.assertFalse((root / 'installed-theme/source-theme').exists())
            self.assertIn('qt6-5compat', (root / 'commands').read_text())
            self.assertEqual((root / 'sddm.conf').read_text().count('Current=HyprFlux-sddm-theme'), 1)
            result = self.run_module('06-sddm.sh', temp, fail_pacman=True)
            self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()
