"""Qt/Kvantum and native Hyprtoolkit are separate theme consumers."""
import configparser
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class QtThemeConfigTests(unittest.TestCase):
    def test_single_platform_theme_supports_both_qt_versions(self):
        text = (ROOT / '.config/hypr/UserConfigs/env-variables.lua').read_text()
        values = re.findall(r'^hl.env\("QT_QPA_PLATFORMTHEME", "([^"]+)"\)', text, re.M)
        self.assertEqual(values, ['qt5ct'])
        self.assertNotIn('QT_STYLE_OVERRIDE', text)

    def test_matching_widget_theme_assets_and_palettes(self):
        kv = configparser.ConfigParser()
        kv.read(ROOT / '.config/Kvantum/kvantum.kvconfig')
        name = kv['General']['theme']
        self.assertEqual(name, 'catppuccin-mocha-blue')
        for suffix in ('svg', 'kvconfig'):
            self.assertTrue((ROOT / '.config/Kvantum' / name / f'{name}.{suffix}').is_file())
        for version in (5, 6):
            conf = configparser.ConfigParser()
            conf.read(ROOT / f'.config/qt{version}ct/qt{version}ct.conf')
            self.assertEqual(conf['Appearance']['style'], 'kvantum')
            self.assertEqual(conf['Appearance']['icon_theme'], 'Papirus-Dark')
            path = conf['Appearance']['color_scheme_path'].replace('__HYPRFLUX_HOME__/', '')
            self.assertTrue((ROOT / path).is_file())

    def test_native_palette_is_mocha_blue_not_qt_configuration(self):
        path = ROOT / '.config/hypr/hyprtoolkit.conf'
        colors = dict(re.findall(r'^(\w+)\s*=\s*(0x[0-9A-Fa-f]{8})$', path.read_text(), re.M))
        self.assertEqual(len(colors), 8)
        self.assertEqual(colors['background'], '0xFF1E1E2E')
        self.assertEqual(colors['text'], '0xFFCDD6F4')
        self.assertEqual(colors['accent'], '0xFF89B4FA')
        self.assertEqual(colors['link_text'], colors['accent'])
        self.assertNotIn('font_size =', path.read_text())

    def test_qt5_engine_is_an_explicit_install_dependency(self):
        text = (ROOT / 'base-installer/install-scripts/01-hypr-pkgs.sh').read_text()
        self.assertRegex(text, r'(?m)^\s+kvantum-qt5\b')

    def test_theme_mirrors_match(self):
        for folder in ('qt5ct', 'qt6ct', 'Kvantum'):
            for source in (ROOT / '.config' / folder).rglob('*'):
                if source.is_file():
                    target = ROOT / 'base-dots/config' / source.relative_to(ROOT / '.config')
                    self.assertEqual(source.read_bytes(), target.read_bytes(), str(source))
        self.assertEqual((ROOT / '.config/hypr/hyprtoolkit.conf').read_bytes(),
                         (ROOT / 'base-dots/config/hypr/hyprtoolkit.conf').read_bytes())


class RealQtThemeTests(unittest.TestCase):
    def test_native_palette_with_real_hyprlang_parser(self):
        if not shutil.which('pkg-config') or not shutil.which('g++'):
            self.skipTest('Hyprlang development library and g++ required')
        flags = subprocess.run(['pkg-config', '--cflags', '--libs', 'hyprlang'],
                               text=True, capture_output=True)
        if flags.returncode:
            self.skipTest('Hyprlang development library required')
        with tempfile.TemporaryDirectory(prefix='hyprflux-palette-') as tmp:
            binary = Path(tmp) / 'probe'
            subprocess.run(['g++', '-std=c++23', str(ROOT / 'tests/hyprtoolkit_palette_probe.cpp'),
                            '-o', str(binary), *flags.stdout.split()], check=True, capture_output=True)
            result = subprocess.run([str(binary), str(ROOT / '.config/hypr/hyprtoolkit.conf')],
                                    text=True, capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)

    def probe(self, version):
        if not shutil.which('pkg-config') or not shutil.which('g++'):
            self.skipTest('Qt development libraries and g++ required')
        flags = subprocess.run(['pkg-config', '--cflags', '--libs', f'Qt{version}Widgets'],
                               text=True, capture_output=True)
        if flags.returncode:
            self.skipTest(f'Qt{version} development libraries required')
        plugin = Path('/usr/lib/qt/plugins/styles/libkvantum.so' if version == 5
                      else '/usr/lib/qt6/plugins/styles/libkvantum.so')
        if not plugin.is_file():
            self.skipTest(f'Qt{version} Kvantum plugin required')
        with tempfile.TemporaryDirectory(prefix='hyprflux-qt-') as tmp:
            home = Path(tmp)
            binary = home / 'probe'
            subprocess.run(['g++', '-std=c++17', '-fPIC', str(ROOT / 'tests/qt_theme_probe.cpp'),
                            '-o', str(binary), *flags.stdout.split()], check=True, capture_output=True)
            config = home / '.config'
            config.mkdir()
            for folder in ('qt5ct', 'qt6ct', 'Kvantum'):
                shutil.copytree(ROOT / '.config' / folder, config / folder)
            for v in (5, 6):
                p = config / f'qt{v}ct/qt{v}ct.conf'
                p.write_text(p.read_text().replace('__HYPRFLUX_HOME__', str(home)))
            # Avoid the real display, session bus, user themes, and style overrides.
            env = {k: v for k, v in os.environ.items() if not k.startswith(('QT_', 'QML'))
                   and k not in ('DISPLAY', 'WAYLAND_DISPLAY', 'DBUS_SESSION_BUS_ADDRESS')}
            env.update(HOME=str(home), XDG_CONFIG_HOME=str(config), QT_QPA_PLATFORM='offscreen',
                       QT_QPA_PLATFORMTHEME='qt5ct')
            result = subprocess.run([str(binary)], env=env, text=True, capture_output=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stderr)
            data = json.loads(result.stdout)
            self.assertTrue(data[f'qt{version}ct_loaded'], result.stderr)
            self.assertTrue(data['kvantum_loaded'], result.stderr)
            self.assertEqual(data['base_style'].lower(), 'kvantum')
            self.assertEqual(data['window'], '#1e1e2e')
            self.assertEqual(data['text'], '#cdd6f4')
            self.assertEqual(data['highlight'], '#89b4fa')
            self.assertEqual(data['icons'], 'Papirus-Dark')

    def test_real_qt5_kvantum_and_platform_theme(self):
        self.probe(5)

    def test_real_qt6_kvantum_and_platform_theme(self):
        self.probe(6)
