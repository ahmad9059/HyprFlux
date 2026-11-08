"""Waybar configuration and adapters; no real updates, power or audio actions."""
import importlib
import importlib.util
import io
import contextlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import select
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
BAR = ROOT / '.config/waybar'
SCRIPTS = ROOT / '.config/hypr/scripts'
sys.path.insert(0, str(SCRIPTS))
previous_bytecode = sys.dont_write_bytecode
try:
    sys.dont_write_bytecode = True
    waybar = importlib.import_module('hyprflux.waybar')
finally:
    sys.dont_write_bytecode = previous_bytecode


def jsonc(path):
    """Remove JSONC comments/trailing commas without touching quoted text."""
    text = re.sub(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*[\s\S]*?\*/',
                  lambda m: m[0] if m[0].startswith('"') else ' ', path.read_text())
    text = re.sub(r'"(?:\\.|[^"\\])*"|,\s*(?=[}\]])',
                  lambda m: m[0] if m[0].startswith('"') else '', text)
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f'{path}: duplicate key {key}')
            result[key] = value
        return result
    return json.loads(text, object_pairs_hook=unique)


def merge(first, later):
    for key, value in later.items():
        if key not in first:
            first[key] = value
        elif isinstance(first[key], dict) and isinstance(value, dict):
            merge(first[key], value)
    return first


def config(path, ancestors=()):
    if path in ancestors:
        raise ValueError('Circular include: ' + str(path))
    result = jsonc(path)
    for name in result.get('include', []):
        included = Path(name.replace('$HOME/.config/waybar', str(BAR)))
        if not included.is_absolute():
            included = path.parent / included
        merge(result, config(included, (*ancestors, path)))
    return result


class ConfigTests(unittest.TestCase):
    def test_every_bank_and_preset_parses_without_duplicate_keys(self):
        for path in [BAR / 'config', *BAR.glob('Modules*'), BAR / 'UserModules', *BAR.joinpath('configs').iterdir()]:
            with self.subTest(path=path):
                self.assertIsInstance(jsonc(path), dict)

    def test_entrypoint_and_preset_share_one_layout(self):
        main = config(BAR / 'config')
        preset = config(BAR / 'configs/HyprFlux-Default-Laptop')
        main.pop('include')
        preset.pop('include')
        self.assertEqual(main, preset)

    def test_user_modules_override_defaults(self):
        includes = jsonc(BAR / 'configs/HyprFlux-Default-Laptop')['include']
        self.assertTrue(includes[0].endswith('/UserModules'))
        value = merge({'clock': {'format': 'mine'}}, jsonc(BAR / 'Modules'))
        self.assertEqual(value['clock']['format'], 'mine')
        self.assertIn('calendar', value['clock'])

    def test_group_references_are_defined_and_non_circular(self):
        data = config(BAR / 'config')
        def walk(name, parents=()):
            self.assertIn(name, data, name)
            self.assertNotIn(name, parents)
            if name.startswith('group/'):
                for child in data[name]['modules']:
                    walk(child, (*parents, name))
        for name in data:
            if name.startswith('group/'):
                walk(name)

    def test_default_preserves_the_original_layout_with_safe_helpers(self):
        data = config(BAR / 'config')
        leaves = []
        def walk(name):
            if name.startswith('group/'):
                for child in data[name]['modules']:
                    walk(child)
            else:
                self.assertIn(name, data)
                leaves.append(name)
        for area in ('modules-left', 'modules-center', 'modules-right'):
            for name in data[area]:
                walk(name)
        self.assertIn('hyprland/window', data['modules-left'])
        self.assertIn('custom/playerctl', data['modules-left'])
        self.assertEqual(data['modules-center'][0], 'hyprland/workspaces#rw')
        self.assertIn('clock', data['modules-center'])
        self.assertEqual(data['modules-right'][0], 'group/app_drawer')
        self.assertEqual(data['modules-right'][-1], 'group/status')
        self.assertNotIn('keyboard-state', leaves)  # no /dev/input permission requirement
        self.assertIn('custom/cava_mviz', leaves)

    def test_all_shell_actions_parse_and_referenced_helpers_exist(self):
        data = config(BAR / 'config')
        def walk(value):
            if not isinstance(value, dict):
                return
            for key, item in value.items():
                if isinstance(item, dict):
                    walk(item)
                elif isinstance(item, str) and (key.startswith('on-') or key in ('exec', 'exec-if')):
                    result = subprocess.run(['sh', '-n', '-c', item], capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, (item, result.stderr))
                    for relative in re.findall(r'\$HOME/(\.config/[^\s\"\']+)', item):
                        self.assertTrue((ROOT / relative).is_file(), relative)
        walk(data)

    def test_workspaces_use_native_click_and_quoted_lua_scroll(self):
        for name, module in jsonc(BAR / 'ModulesWorkspaces').items():
            self.assertNotIn('on-click', module, name)
            self.assertNotIn('sort-by-number', module)
            for key in ('on-scroll-up', 'on-scroll-down'):
                if key not in module:
                    continue
                args = shlex.split(module[key])
                self.assertEqual(args[:2], ['hyprctl', 'dispatch'])
                self.assertEqual(len(args), 3, args)
                self.assertTrue(args[2].startswith('hl.dsp.focus('))

    def test_options_live_in_correct_objects_and_polling_is_reasonable(self):
        data = jsonc(BAR / 'Modules')
        self.assertEqual(data['disk']['paths'], ['/'])
        self.assertNotIn('path', data['disk'])
        self.assertIn('actions', data['clock'])
        self.assertNotIn('actions', data)
        self.assertIn('ignored-sinks', data['pulseaudio'])
        self.assertNotIn('ignored-sinks', data['pulseaudio']['format-icons'])
        self.assertGreaterEqual(data['clock']['interval'], 60)
        self.assertGreaterEqual(data['cpu']['interval'], 5)
        self.assertNotIn('hwmon-path', data['temperature'])
        self.assertIn('input-filename', data['temperature'])

    def test_css_uses_only_defined_colors_and_no_phantom_animations(self):
        css = (BAR / 'style/HyprFlux-Default.css').read_text()
        colors = set(re.findall(r'@define-color\s+([\w-]+)', (BAR / 'hyprflux-colors.css').read_text()))
        used = set(re.findall(r'@([\w-]+)', css)) - {'import'}
        self.assertLessEqual(used, colors)
        self.assertNotIn('animation:', css)
        self.assertIn('font-family: "JetBrainsMono Nerd Font"', css)
        self.assertIn('border-radius: 20px', css)
        self.assertIn('#custom-cava_mviz { color: @pink; }', css)

    def test_gtk3_css_parses(self):
        code = '''
import sys, json
try:
    import gi
    gi.require_version('Gtk', '3.0')
    from gi.repository import Gtk
except (ImportError, ValueError):
    sys.exit(77)
errors = []
p = Gtk.CssProvider()
p.connect('parsing-error', lambda _, section, error: errors.append(error.message))
p.load_from_path(sys.argv[1])
print(json.dumps(errors))
'''
        result = subprocess.run([sys.executable, '-c', code, str(BAR / 'style.css')], capture_output=True, text=True)
        if result.returncode == 77:
            self.skipTest('GTK3 Python bindings required')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [])

    def test_deployment_mirror_matches(self):
        for path in BAR.rglob('*'):
            if path.is_file():
                self.assertEqual(path.read_bytes(), (ROOT / 'base-dots/config/waybar' / path.relative_to(BAR)).read_bytes())
        for relative in ('WaybarStatus.py', 'WaybarScripts.sh', 'WaybarCava.sh', 'Distro_update.sh', 'hyprflux/waybar.py'):
            self.assertEqual((SCRIPTS / relative).read_bytes(),
                             (ROOT / 'base-dots/config/hypr/scripts' / relative).read_bytes())

    def test_detector_uses_structured_stable_sensor_configuration(self):
        text = (ROOT / 'modules/16-hardware-detect.sh').read_text()
        self.assertIn("'hwmon-name': identity", text)
        self.assertNotIn("sed -i '/\"hwmon-path\"", text)

    def test_detector_updates_both_orientations_without_touching_overrides(self):
        text = (ROOT / 'modules/16-hardware-detect.sh').read_text()
        code = re.search(r"if python3 .*?<<'PY'\n([\s\S]*?)\nPY", text)[1]
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            sensor = base / 'hwmon99/temp1_input'
            sensor.parent.mkdir()
            sensor.write_text('45000')
            (sensor.parent / 'name').write_text('k10temp\n')
            for name in ('Modules', 'ModulesVertical'):
                (base / name).write_bytes((BAR / name).read_bytes())
            user = base / 'UserModules'
            user.write_text('{"temperature":{"critical-threshold":95}}')
            for _ in range(2):
                subprocess.run([sys.executable, '-c', code, str(base), str(sensor)], check=True, capture_output=True)
                for name, key in [('Modules', 'temperature'), ('ModulesVertical', 'temperature#vertical')]:
                    module = json.loads((base / name).read_text())[key]
                    self.assertEqual(module['hwmon-name'], 'k10temp')
                    self.assertEqual(module['input-filename'], 'temp1_input')
                    self.assertNotIn('hwmon-path-abs', module)
                self.assertEqual(user.read_text(), '{"temperature":{"critical-threshold":95}}')


class HelperTests(unittest.TestCase):
    def check_result(self, code, stdout='', stderr=''):
        return subprocess.CompletedProcess(['checkupdates'], code, stdout, stderr)

    def test_no_updates_and_errors_are_distinguished(self):
        with patch.object(waybar.shutil, 'which', return_value='/usr/bin/checkupdates'):
            for code, expected in ((0, 'updated'), (2, 'updated'), (1, 'error'), (127, 'error')):
                with patch.object(waybar.subprocess, 'run', return_value=self.check_result(code)) as run:
                    self.assertEqual(waybar.update_status()['class'], expected)
                    self.assertEqual(run.call_count, 1)

    def test_update_metadata_is_encoded_not_interpolated(self):
        output = 'name<test> 1 -> 2\nquote"pkg 2 -> 3\n'
        with patch.object(waybar.shutil, 'which', return_value='checkupdates'), \
             patch.object(waybar.subprocess, 'run', return_value=self.check_result(0, output)):
            value = json.loads(json.dumps(waybar.update_status()))
        self.assertEqual(value['text'], ' 2')
        self.assertIn('quote"pkg', value['tooltip'])
        self.assertIn('Official repositories only', value['tooltip'])

    def test_missing_checkupdates_and_timeout_are_explicit(self):
        with patch.object(waybar.shutil, 'which', return_value=None):
            self.assertEqual(waybar.update_status()['class'], 'unavailable')
        with patch.object(waybar.shutil, 'which', return_value='checkupdates'), \
             patch.object(waybar.subprocess, 'run', side_effect=subprocess.TimeoutExpired('checkupdates', 90)):
            self.assertEqual(waybar.update_status()['class'], 'error')

    def test_monitors_share_cached_result_and_corrupt_cache_is_replaced(self):
        with tempfile.TemporaryDirectory() as tmp, \
             patch.dict(os.environ, {'XDG_RUNTIME_DIR': tmp}), \
             patch.object(waybar, 'update_status', return_value=waybar.payload('2', 'updates', 'updates')) as check:
            self.assertEqual(waybar.updates(), waybar.updates())
            self.assertEqual(check.call_count, 1)
            (waybar.runtime() / 'waybar-updates.json').write_text('{broken')
            waybar.updates()
            self.assertEqual(check.call_count, 2)

    def test_concurrent_monitor_checks_run_one_transaction(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            calls = base / 'calls'
            command = base / 'checkupdates'
            command.write_text('#!/bin/sh\necho check >> "$TEST_CALLS"\necho "pkg 1 -> 2"\n')
            command.chmod(0o755)
            env = {**os.environ, 'XDG_RUNTIME_DIR': tmp, 'TEST_CALLS': str(calls),
                   'PATH': tmp + os.pathsep + os.environ['PATH']}
            children = [subprocess.Popen([sys.executable, str(SCRIPTS / 'WaybarStatus.py'), 'updates'],
                                         env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                        for _ in range(2)]
            try:
                for child in children:
                    out, err = child.communicate(timeout=10)
                    self.assertEqual(child.returncode, 0, err)
                    self.assertEqual(json.loads(out)['text'], ' 1')
            finally:
                for child in children:
                    if child.poll() is None:
                        child.kill()
                        child.communicate()
            self.assertEqual(calls.read_text().splitlines(), ['check'])

    def test_update_refresh_signals_only_current_users_bars(self):
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ, {'XDG_RUNTIME_DIR': tmp}), \
             patch.object(waybar.subprocess, 'run') as run:
            cache = waybar.runtime() / 'waybar-updates.json'
            cache.write_text('{}')
            waybar.refresh_updates()
            self.assertFalse(cache.exists())
        run.assert_called_once_with(['pkill', '-u', str(os.getuid()), '-RTMIN+8', '-x', 'waybar'], check=False)

    def test_custom_media_metadata_with_quotes_and_newlines_is_valid_json(self):
        fields = ['Artist "name"\nSecond line', '<song> & title', 'Playing']
        with patch.object(waybar.subprocess, 'run', side_effect=[self.check_result(0, text) for text in fields]):
            value = json.loads(json.dumps(waybar.media()))
        self.assertIn('<song> & title', value['text'])
        self.assertEqual(value['class'], 'playing')

    def test_no_player_hides_legacy_media(self):
        with patch.object(waybar.subprocess, 'run', return_value=self.check_result(1)):
            self.assertEqual(waybar.media()['text'], '')

    def test_terminal_and_files_use_argv_not_shell(self):
        apps = {'term': ['kitty', '--single-instance'], 'files': ['thunar', '/a path']}
        with patch.object(waybar, 'defaults', return_value=apps), \
             patch.object(waybar.shutil, 'which', return_value='/installed'), \
             patch.object(waybar.subprocess, 'call', return_value=0) as call:
            waybar.launch('--nmtui')
            call.assert_called_with(['kitty', '--single-instance', '--title', 'nmtui', '-e', 'nmtui'])
            waybar.launch('--files')
            call.assert_called_with(['thunar', '/a path'])
            with self.assertRaises(ValueError):
                waybar.launch('--unknown')

    def test_defaults_ignore_comments_and_never_evaluate_lua(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(waybar, 'HYPR', Path(tmp)):
            directory = Path(tmp) / 'UserConfigs'
            directory.mkdir()
            (directory / 'user-defaults.lua').write_text('''
-- old term = "wrong"
local defaults = {
    term = "kitty --single-instance", -- preferred terminal
    files = "thunar /example", -- files
}
error("must not execute")
''')
            self.assertEqual(waybar.defaults(), {'term': ['kitty', '--single-instance'], 'files': ['thunar', '/example']})

    def test_missing_terminal_tool_does_not_launch(self):
        with patch.object(waybar, 'defaults', return_value={'term': ['kitty'], 'files': ['thunar']}), \
             patch.object(waybar.shutil, 'which', return_value=None), \
             patch.object(waybar.subprocess, 'call') as call:
            with self.assertRaises(RuntimeError):
                waybar.launch('--btop')
            call.assert_not_called()

    def test_cava_instances_have_private_configs_and_no_global_kills(self):
        text = (SCRIPTS / 'hyprflux/waybar.py').read_text()
        self.assertIn("TemporaryDirectory(prefix='waybar-cava-'", text)
        self.assertIn('process.terminate()', text)
        self.assertNotIn('bar_cava_config', text)
        self.assertNotIn('pkill -f', text)

    def test_two_cava_bars_can_run_and_stop_independently(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            stub = base / 'cava'
            stub.write_text(f'#!{sys.executable}\n' + '''
import json, os, pathlib, signal, sys
config = pathlib.Path(sys.argv[2])
(config.parent / 'child.json').write_text(json.dumps({'pid': os.getpid(), 'config': str(config)}))
print('0;1;7;', flush=True)
signal.pause()
''')
            stub.chmod(0o755)
            env = {**os.environ, 'XDG_RUNTIME_DIR': tmp, 'PATH': tmp + os.pathsep + os.environ['PATH']}
            processes = []
            try:
                for _ in range(2):
                    process = subprocess.Popen([sys.executable, str(SCRIPTS / 'WaybarStatus.py'), 'cava'],
                                               env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                    processes.append(process)
                    self.assertTrue(select.select([process.stdout], [], [], 10)[0], 'visualizer did not start')
                    self.assertEqual(process.stdout.readline().strip(), '▁▂█')
                children = list(base.glob('hyprflux-*/waybar-cava-*/child.json'))
                self.assertEqual(len(children), 2)
                self.assertEqual(len({json.loads(p.read_text())['config'] for p in children}), 2)
                processes[0].terminate()
                processes[0].wait(timeout=5)
                self.assertIsNone(processes[1].poll(), 'stopping one visualizer stopped another')
                self.assertEqual(len(list(base.glob('hyprflux-*/waybar-cava-*'))), 1)
            finally:
                for process in processes:
                    if process.poll() is None:
                        process.terminate()
                        process.wait(timeout=5)
                    process.stdout.close()
                    process.stderr.close()
            self.assertEqual(list(base.glob('hyprflux-*/waybar-cava-*')), [])


class InstallerTests(unittest.TestCase):
    def test_waybar_is_not_overwritten_by_the_second_copy_phase(self):
        text = (ROOT / 'base-dots/scripts/lib_copy.sh').read_text()
        phase = text.split('copy_phase2() {', 1)[1].split('\n}', 1)[0]
        directories = re.search(r'local DIR="([^"]+)"', phase)[1].split()
        self.assertNotIn('waybar', directories)
        main = (ROOT / 'base-dots/copy.sh').read_text()
        self.assertNotIn('[Extra] Neon Circuit.css', main)
        self.assertNotIn('config_remove', main)

    def test_copy_preserves_overrides_unique_presets_and_relative_selection(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            source = base / 'config/waybar'
            shutil.copytree(BAR, source)
            home = base / 'home'
            live = home / '.config/waybar'
            shutil.copytree(BAR, live)
            (live / 'UserModules').write_text('{"clock":{"format":"mine"}}')
            custom = live / 'configs/personal'
            custom.write_text('{"modules-center":["clock"]}')
            (live / 'config').unlink()
            (live / 'config').symlink_to('configs/personal')
            (live / 'style.css').unlink()
            (live / 'style.css').symlink_to('style/HyprFlux-Default.css')
            script = '''
set -euo pipefail
source "$LIB_COPY"
get_backup_dirname() { date +%s%N; }
copy_waybar "$HOME/log"
copy_waybar "$HOME/log"
'''
            subprocess.run(['bash', '-c', script], cwd=base, check=True, capture_output=True,
                           env={**os.environ, 'HOME': str(home), 'LIB_COPY': str(ROOT / 'base-dots/scripts/lib_copy.sh')})
            self.assertEqual((live / 'UserModules').read_text(), '{"clock":{"format":"mine"}}')
            self.assertEqual((live / 'config').readlink(), Path('configs/personal'))
            self.assertTrue((live / 'config').is_file())
            self.assertTrue((live / 'style.css').is_file())
            self.assertEqual(custom.read_text(), '{"modules-center":["clock"]}')


class WeatherTests(unittest.TestCase):
    def setUp(self):
        spec = importlib.util.spec_from_file_location('waybar_weather', ROOT / '.config/hypr/UserScripts/Weather.py')
        self.weather = importlib.util.module_from_spec(spec)
        previous = sys.dont_write_bytecode
        try:
            sys.dont_write_bytecode = True
            spec.loader.exec_module(self.weather)
        finally:
            sys.dont_write_bytecode = previous

    def test_severe_weather_has_its_own_class(self):
        self.assertEqual(self.weather.category(200, True), 'severe')

    def test_day_night_uses_weather_location_time(self):
        today = {'astronomy': [{'sunrise': '06:30 AM', 'sunset': '05:30 PM'}]}
        self.assertTrue(self.weather.is_day({'localObsDateTime': '2026-11-08 01:00 PM'}, today))
        self.assertFalse(self.weather.is_day({'localObsDateTime': '2026-11-08 11:00 PM'}, today))
        self.assertFalse(self.weather.is_day({'isday': '0'}, today))

    def test_malformed_weather_still_emits_valid_json(self):
        with patch.object(self.weather, 'fetch', return_value={'current_condition': [{'weatherCode': 'bad'}], 'weather': [{}]}), \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.weather.main()
        self.assertEqual(json.loads(output.getvalue())['alt'], 'error')

    def test_weather_tooltip_escapes_network_text(self):
        data = {'current_condition': [{'weatherCode': '113', 'weatherDesc': [{'value': '<sun> & clouds'}]}],
                'weather': [{}]}
        with tempfile.TemporaryDirectory() as tmp, patch.dict(os.environ, {'HOME': tmp}), \
             patch.object(self.weather, 'fetch', return_value=data), \
             contextlib.redirect_stdout(io.StringIO()) as output:
            self.weather.main()
        tooltip = json.loads(output.getvalue())['tooltip']
        self.assertIn('&lt;sun&gt; &amp; clouds', tooltip)
        self.assertNotIn('<sun>', tooltip)


if __name__ == '__main__':
    unittest.main()
