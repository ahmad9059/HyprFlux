"""wlogout layout, assets, geometry, and the hibernate guard; nothing powers off."""
import json
import os
from pathlib import Path
import re
import shutil
import stat
import struct
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
WLOGOUT = ROOT / '.config/wlogout'
HYPR = ROOT / '.config/hypr'
LABELS = ['lock', 'logout', 'suspend', 'hibernate', 'reboot', 'shutdown']


def entries(path=WLOGOUT / 'layout'):
    """wlogout's layout is a stream of JSON objects, not a JSON array."""
    text, decoder, position, result = path.read_text(), json.JSONDecoder(), 0, []
    while position < len(text):
        while position < len(text) and text[position].isspace():
            position += 1
        if position == len(text):
            break
        value, position = decoder.raw_decode(text, position)
        result.append(value)
    return result


def png_size(path):
    data = path.read_bytes()[:24]
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    return struct.unpack('>II', data[16:24])


class LayoutTests(unittest.TestCase):
    def test_order_puts_destructive_actions_last_and_keys_are_stable(self):
        items = entries()
        self.assertEqual([i['label'] for i in items], LABELS)
        self.assertEqual({i['label']: i['keybind'] for i in items},
                         {'lock': 'l', 'logout': 'e', 'suspend': 'u', 'hibernate': 'h', 'reboot': 'r', 'shutdown': 's'})
        self.assertTrue(all(i['action'].strip() and i['text'] for i in items))

    def test_script_actions_exist_and_are_executable(self):
        for item in entries():
            match = re.match(r'\$HOME/(\.config/\S+)', item['action'])
            if match:
                path = ROOT / match.group(1)
                self.assertTrue(path.is_file(), item['action'])
                self.assertTrue(path.stat().st_mode & stat.S_IXUSR, item['action'])

    def test_hibernate_never_calls_systemctl_directly(self):
        action = {i['label']: i['action'] for i in entries()}['hibernate']
        self.assertTrue(action.endswith('/Hibernate.sh'))
        self.assertNotIn('systemctl', action)


class AssetTests(unittest.TestCase):
    def test_every_button_has_normal_and_hover_icons_in_css(self):
        css = (WLOGOUT / 'style.css').read_text()
        for label in LABELS:
            normal = re.search(r'#%s\s*\{[^}]*url\("\./icons/([^"]+)"\)' % label, css)
            hover = re.search(r'#%s:hover\s*\{[^}]*url\("\./icons/([^"]+)"\)' % label, css)
            self.assertTrue(normal and hover, label)
            for match in (normal, hover):
                self.assertTrue((WLOGOUT / 'icons' / match.group(1)).is_file(), match.group(1))

    def test_icons_are_sharp_and_there_are_no_unused_files(self):
        css = (WLOGOUT / 'style.css').read_text()
        used = set(re.findall(r'icons/([^"]+\.png)', css))
        self.assertEqual({p.name for p in (WLOGOUT / 'icons').iterdir()}, used)
        for name in used:
            self.assertEqual(png_size(WLOGOUT / 'icons' / name), (512, 512), name)

    def test_every_theme_color_used_is_defined_by_the_generated_block(self):
        css = (WLOGOUT / 'style.css').read_text()
        defined = set(re.findall(r'@define-color\s+([\w-]+)', css))
        used = set(re.findall(r'@([\w-]+)', css.replace('@define-color', ''))) - {'keyframes'}
        self.assertEqual(used - defined, set())
        self.assertLessEqual({'color12', 'logout-danger'}, defined)

    def test_only_session_ending_actions_turn_red(self):
        css = (WLOGOUT / 'style.css').read_text()
        match = re.search(r'((?:#\w+:hover,\s*)*#\w+:hover)\s*\{[^}]*@logout-danger', css)
        self.assertEqual(set(re.findall(r'#(\w+):hover', match.group(1))), {'logout', 'reboot', 'shutdown'})

    def test_css_has_no_animation_without_keyframes(self):
        css = (WLOGOUT / 'style.css').read_text()
        for name in re.findall(r'animation:\s*([\w-]+)', css):
            self.assertIn('@keyframes ' + name, css)

    def test_gtk3_css_parses_without_errors(self):
        # A fresh interpreter: other tests load GTK4, and one process cannot hold both.
        script = '''
import json, sys
try:
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk
except (ImportError, ValueError):
    sys.exit(77)
errors = []
provider = Gtk.CssProvider()
provider.connect("parsing-error", lambda _p, section, error: errors.append([section.get_start_line() + 1, error.message]))
provider.load_from_path(sys.argv[1])
print(json.dumps(errors))
'''
        result = subprocess.run([sys.executable, '-c', script, str(WLOGOUT / 'style.css')],
                                text=True, capture_output=True, timeout=30)
        if result.returncode == 77:
            self.skipTest('GTK3 Python bindings required')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [])

    def test_mirror_matches(self):
        mirror = ROOT / 'base-dots/config/wlogout'
        def files(base):
            return {str(p.relative_to(base)): p.read_bytes() for p in base.rglob('*') if p.is_file()}
        self.assertEqual(files(WLOGOUT), files(mirror))
        for name in ('Hibernate.sh', 'SleepAction.sh', 'Wlogout.sh'):
            self.assertEqual((HYPR / 'scripts' / name).read_bytes(),
                             (ROOT / 'base-dots/config/hypr/scripts' / name).read_bytes())

    def test_menu_background_is_blurred_by_a_layer_rule(self):
        rules = (HYPR / 'UserConfigs/window-rules.lua').read_text()
        self.assertRegex(rules, r'hl\.layer_rule\(\{[^}]*blur = true[^}]*namespace = "logout_dialog"')
        self.assertEqual(rules, (ROOT / 'base-dots/config/hypr/UserConfigs/window-rules.lua').read_text())


@unittest.skipUnless(shutil.which('jq'), 'jq required')
class ScriptTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.dir = Path(self.temp.name)
        self.calls = self.dir / 'calls'
        self.runtime = self.dir / 'runtime'
        self.runtime.mkdir(mode=0o700)
        self.wl = self.dir / 'wlogout-config'
        shutil.copytree(WLOGOUT, self.wl)
        self.stub('busctl', '''case "$*" in
*CanSuspend*) value="${TEST_SUSPEND:-yes}" ;;
*) value="${TEST_HIBERNATE:-yes}" ;;
esac
printf '{"data":["%s"]}\\n' "$value"''')

    def stub(self, name, body):
        path = self.dir / name
        path.write_text('#!/bin/sh\n' + body + '\n')
        path.chmod(0o755)

    def run_script(self, script, extra_env=None):
        env = {**os.environ, 'PATH': str(self.dir) + os.pathsep + os.environ['PATH'], 'XDG_RUNTIME_DIR': str(self.runtime),
               'HYPRFLUX_WLOGOUT_DIR': str(self.wl), **(extra_env or {})}
        return subprocess.run([str(script)], env=env, text=True, capture_output=True, timeout=10)

    def recorded(self):
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def cmdline(self, text):
        path = self.dir / 'cmdline'
        path.write_text(text + '\n')
        return {'HYPRFLUX_CMDLINE_FILE': str(path)}

    def hibernate(self, cmdline, *args, env=None):
        self.stub('systemctl', 'echo "systemctl $*" >> "%s"' % self.calls)
        self.stub('notify-send', 'echo "notify $*" >> "%s"' % self.calls)
        return subprocess.run([str(HYPR / 'scripts/Hibernate.sh'), *args], text=True, capture_output=True, timeout=10,
                              env={**os.environ, 'PATH': str(self.dir) + os.pathsep + os.environ['PATH'],
                                   **self.cmdline(cmdline), **(env or {})})

    def menu(self, monitors, cmdline='root=x rw resume=UUID=abc'):
        self.calls.unlink(missing_ok=True)
        self.stub('hyprctl', "echo '%s'" % json.dumps(monitors) if monitors is not None else 'exit 1')
        self.stub('pgrep', 'exit 1')
        self.stub('wlogout', 'echo "$*" >> "%s"; while [ "$#" -gt 0 ]; do if [ "$1" = -l ]; then cp "$2" "%s"; fi; shift; done' % (self.calls, self.dir / 'captured-layout'))
        result = self.run_script(HYPR / 'scripts/Wlogout.sh', self.cmdline(cmdline))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.recorded()), 1)
        return self.recorded()[0]

    def monitor(self, width, height, scale=1, transform=0, id=0, focused=True):
        return {'id': id, 'focused': focused, 'width': width, 'height': height, 'scale': scale, 'transform': transform}

    def test_hibernate_is_refused_without_a_resume_device(self):
        for cmdline in ('root=x rw quiet', 'root=x noresume rw', 'root=x resume= rw'):
            self.calls.unlink(missing_ok=True)
            result = self.hibernate(cmdline)
            self.assertEqual(result.returncode, 1, cmdline)
            self.assertTrue(self.recorded()[0].startswith('notify '), cmdline)
            self.assertFalse(any(line.startswith('systemctl') for line in self.recorded()), cmdline)

    def test_hibernate_runs_when_resume_is_configured_or_overridden(self):
        for cmdline, env in (('root=x resume=UUID=abc rw', None), ('root=x rw resume=/dev/x', None),
                             ('root=x rw', {'HYPRFLUX_ALLOW_HIBERNATE': '1'})):
            self.calls.unlink(missing_ok=True)
            self.assertEqual(self.hibernate(cmdline, env=env).returncode, 0, cmdline)
            self.assertEqual(self.recorded(), ['systemctl hibernate'], cmdline)

    def test_availability_check_is_silent_and_never_hibernates(self):
        self.assertEqual(self.hibernate('root=x rw', '--check').returncode, 1)
        self.assertEqual(self.hibernate('root=x rw resume=UUID=abc', '--check').returncode, 0)
        self.assertEqual(self.recorded(), [])

    def test_menu_is_sized_in_logical_pixels_and_shown_on_the_focused_monitor(self):
        base = '--protocol layer-shell --show-binds -l %s/layout -C %s/style.css' % (self.wl, self.wl)
        cases = (
            ([self.monitor(2560, 1440)], '-b 6 -P 0 -L 380 -R 380 -T 570 -B 570'),
            ([self.monitor(3840, 2160, 1.5)], '-b 6 -P 0 -L 380 -R 380 -T 570 -B 570'),
            ([self.monitor(1920, 1080)], '-b 6 -P 0 -L 282 -R 282 -T 427 -B 427'),
            ([self.monitor(1280, 720)], '-b 6 -P 0 -L 160 -R 160 -T 280 -B 280'),
            ([self.monitor(2560, 1440, id=0, focused=False), self.monitor(1920, 1080, id=1)],
             '-b 6 -P 1 -L 282 -R 282 -T 427 -B 427'),
        )
        for monitors, expected in cases:
            self.assertEqual(self.menu(monitors), '%s -b %s' % (base, expected.split('-b ', 1)[1]), monitors)

    def test_rotated_monitors_swap_width_and_height(self):
        args = self.menu([self.monitor(2560, 1440, transform=1)]).split()
        values = {flag: int(args[args.index(flag) + 1]) for flag in ('-L', '-R', '-T', '-B')}
        self.assertEqual(values, {'-L': 72, '-R': 72, '-T': 1172, '-B': 1172})

    def test_cards_are_square_and_the_row_fits_on_every_size(self):
        for width, height, scale in ((2560, 1440, 1), (1920, 1080, 1), (1366, 768, 1), (3840, 2160, 2), (1024, 768, 1)):
            args = self.menu([self.monitor(width, height, scale)]).split()
            side, vertical = (int(args[args.index(flag) + 1]) for flag in ('-L', '-T'))
            logical_width, logical_height = int(width / scale), int(height / scale)
            card = (logical_width - 2 * side) // 6
            self.assertAlmostEqual(card, logical_height - 2 * vertical, delta=1, msg=(width, height, scale))  # odd sizes round by 1px
            self.assertGreaterEqual(card, 124 + 28, (width, height, scale))  # fits the CSS min-width plus margins
            self.assertLessEqual(6 * card, logical_width * 9 // 10, (width, height, scale))

    def test_hibernate_is_left_out_when_resume_is_not_configured(self):
        args = self.menu([self.monitor(2560, 1440)], cmdline='root=x rw').split()
        layout = Path(args[args.index('-l') + 1])
        self.assertTrue(str(layout).startswith(str(self.runtime) + '/'))
        self.assertEqual([i['label'] for i in entries(self.dir / 'captured-layout')], [l for l in LABELS if l != 'hibernate'])
        self.assertFalse(layout.exists(), 'temporary layout is removed after the menu exits')
        self.assertEqual(args[args.index('-b') + 1], '5')
        self.assertEqual(args[args.index('-L') + 1], '530')
        self.assertEqual(entries(self.wl / 'layout'), entries(WLOGOUT / 'layout'), 'the real layout is never modified')

    def test_filtered_layout_is_used_without_a_runtime_directory(self):
        self.calls.unlink(missing_ok=True)
        self.stub('hyprctl', 'exit 1')
        self.stub('pgrep', 'exit 1')
        self.stub('wlogout', 'echo "$*" >> "%s"' % self.calls)
        env = {**os.environ, 'PATH': str(self.dir) + os.pathsep + os.environ['PATH'], 'HYPRFLUX_WLOGOUT_DIR': str(self.wl),
               **self.cmdline('root=x rw')}
        env.pop('XDG_RUNTIME_DIR', None)
        subprocess.run([str(HYPR / 'scripts/Wlogout.sh')], env=env, check=True, timeout=10)
        self.assertNotIn('-l %s/layout' % self.wl, self.recorded()[0])
        self.assertIn('-b 5', self.recorded()[0])

    def test_policy_denial_blocks_hibernate_even_with_resume(self):
        for capability in ('no', 'na'):
            self.calls.unlink(missing_ok=True)
            result = self.hibernate('resume=UUID=abc', env={'TEST_HIBERNATE': capability})
            self.assertEqual(result.returncode, 1)
            self.assertFalse(any(line.startswith('systemctl') for line in self.recorded()))

    def test_noresume_cannot_be_overridden(self):
        result = self.hibernate('resume=UUID=abc noresume', env={'HYPRFLUX_ALLOW_HIBERNATE': '1'})
        self.assertEqual(result.returncode, 1)

    def test_both_unavailable_actions_are_hidden(self):
        self.stub('busctl', 'echo \'{"data":["no"]}\'')
        args = self.menu(None)
        self.assertIn('-b 4', args)
        self.assertEqual([i['label'] for i in entries(self.dir / 'captured-layout')],
                         ['lock', 'logout', 'reboot', 'shutdown'])

    def test_sleep_key_falls_back_to_hibernate(self):
        self.stub('systemctl', 'echo "systemctl $*" >> "%s"' % self.calls)
        env = {**self.cmdline('resume=UUID=abc'), 'TEST_SUSPEND': 'no'}
        result = subprocess.run([str(HYPR / 'scripts/SleepAction.sh'), 'sleep'],
                                env={**os.environ, 'PATH': str(self.dir) + os.pathsep + os.environ['PATH'], **env},
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.recorded(), ['systemctl hibernate'])

    def test_menu_still_opens_when_monitor_information_is_unavailable(self):
        args = self.menu(None)
        self.assertIn('-b 6', args)
        for flag in (' -P ', ' -L ', ' -T '):
            self.assertNotIn(flag, args)

    def test_menu_toggle_closes_only_wlogout(self):
        self.stub('pgrep', 'exit 0')
        self.stub('pkill', 'echo "pkill $*" >> "%s"' % self.calls)
        self.stub('wlogout', 'echo started >> "%s"' % self.calls)
        self.assertEqual(self.run_script(HYPR / 'scripts/Wlogout.sh').returncode, 0)
        self.assertEqual(self.recorded(), ['pkill -x wlogout'])
