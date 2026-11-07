"""Desktop workflow regressions. External actions are mocked, never host IPC."""
import contextlib
import ast
import json
import os
import re
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / '.config/hypr/scripts'
sys.dont_write_bytecode = True
sys.path.insert(0, str(SCRIPTS))
from hyprflux import common, runtime, wallpaper, screenshot, settings, update, devices


def result(stdout='', returncode=0, stderr=''):
    return subprocess.CompletedProcess([], returncode, stdout, stderr)


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.private = self.root / 'runtime'
        self.private.mkdir(mode=0o700)
        self.hypr = self.root / '.config/hypr'
        self.hypr.mkdir(parents=True)
        self.stack = contextlib.ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(patch.dict(os.environ, {
            'HOME': str(self.root), 'XDG_RUNTIME_DIR': str(self.private),
            'XDG_STATE_HOME': str(self.root / 'state'),
            'XDG_CACHE_HOME': str(self.root / 'cache'),
            'HYPRLAND_INSTANCE_SIGNATURE': 'unit-test',
        }))
        for module in (common, wallpaper, screenshot, settings, update):
            self.stack.enter_context(patch.object(module, 'HYPR', self.hypr))
        for module in (runtime, wallpaper, screenshot, settings, update, devices):
            self.stack.enter_context(patch.object(module, 'notify'))

    def image(self, name='wallpaper with spaces.png'):
        path = self.root / 'Pictures/wallpapers' / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'image')
        return path

    def test_lua_serialization_roundtrips_unicode_quotes_and_newlines(self):
        if not shutil.which('lua'):
            self.skipTest('Lua interpreter required')
        text = 'a\'"\\\n; os.execute("false") — 日本語'
        value = subprocess.check_output(['lua', '-e', 'io.write(' + common.lua(text) + ')'])
        self.assertEqual(value.decode(), text)
        self.assertEqual(common.lua({'follow': False}), '{["\\102\\111\\108\\108\\111\\119"]=false}')

    def test_private_runtime_rejects_shared_directory(self):
        self.private.chmod(0o755)
        with self.assertRaises(RuntimeError):
            common.runtime()

    def test_private_runtime_rejects_symlink(self):
        link = self.root / 'link'
        link.symlink_to(self.private)
        with patch.dict(os.environ, {'XDG_RUNTIME_DIR': str(link)}):
            with self.assertRaises(RuntimeError):
                common.runtime()

    def test_eval_rejects_textual_errors_even_with_zero_exit(self):
        with patch.object(common, 'run', return_value=result('error: bad action')):
            with self.assertRaises(RuntimeError):
                common.evaluate('anything')

    def test_typed_option_preserves_asymmetric_gaps(self):
        with patch.object(runtime, 'run', return_value=result(json.dumps({'css': '1 2 3 4'}))):
            self.assertEqual(runtime.option('general.gaps_in'), '1 2 3 4')
        with patch.object(runtime, 'run', return_value=result(json.dumps({'bool': False}))):
            self.assertIs(runtime.option('animations.enabled'), False)

    def test_game_mode_roundtrip_preserves_exact_state(self):
        original = dict(runtime.GAME)
        original.update({'general.gaps_in': '1 2 3 4', 'general.gaps_out': '4 3 2 1',
                         'animations.enabled': True, 'decoration.rounding': 13})
        current = dict(original)
        with patch.object(runtime, 'option', side_effect=lambda key: current[key]), patch.object(runtime, 'evaluate') as evaluate:
            runtime.game_mode()
            self.assertEqual(common.read_json(common.runtime() / 'gamemode.json'), original)
            self.assertEqual(evaluate.call_args.args[0], runtime.config(runtime.GAME))
            current.update(runtime.GAME)
            runtime.game_mode()
            self.assertEqual(evaluate.call_args.args[0], runtime.config(original))
            self.assertFalse((common.runtime() / 'gamemode.json').exists())

    def test_game_mode_failed_enable_does_not_leave_state(self):
        with patch.object(runtime, 'option', side_effect=lambda k: runtime.GAME[k]), patch.object(runtime, 'evaluate', side_effect=[RuntimeError('failed'), None]) as evaluate:
            with self.assertRaises(RuntimeError):
                runtime.game_mode()
            self.assertEqual(evaluate.call_count, 2)
        self.assertFalse((common.runtime() / 'gamemode.json').exists())

    def test_game_mode_does_not_overwrite_settings_after_reload(self):
        common.write_json(common.runtime() / 'gamemode.json', runtime.GAME)
        current = dict(runtime.GAME, **{'general.border_size': 3})
        with patch.object(runtime, 'option', side_effect=lambda k: current[k]), patch.object(runtime, 'evaluate') as evaluate:
            runtime.game_mode()
            evaluate.assert_not_called()
        self.assertFalse((common.runtime() / 'gamemode.json').exists())

    def test_game_mode_css_gaps_use_typed_lua_tables(self):
        code = runtime.config({'general.gaps_in': '1 2 3 4'})
        for name, value in zip(('top', 'right', 'bottom', 'left'), (1, 2, 3, 4)):
            self.assertIn('[' + common.lua(name) + ']=' + str(value), code)

    def test_dropdown_uses_logical_rotated_focused_geometry(self):
        self.assertEqual(runtime.geometry({'width': 2000, 'height': 1000, 'scale': 2,
                                           'transform': 1, 'x': 100, 'y': 200}), (187, 250, 325, 500))

    def test_terminal_identity_is_passed_as_argv_not_source(self):
        command = runtime.terminal_command(['kitty -e "program with spaces"'], 'unique-app')
        self.assertEqual(command, ['kitty', '--class', 'unique-app', '--title', 'unique-app', '-e', 'program with spaces'])
        with self.assertRaises(RuntimeError):
            runtime.terminal_command(['unidentified-terminal'], 'unique')

    def test_dropdown_timeout_never_targets_an_unrelated_window(self):
        unrelated = {'address': '0x123', 'class': 'browser'}
        def query(name):
            return [unrelated] if name == 'clients' else [{'focused': True, 'width': 1000, 'height': 800, 'x': 0, 'y': 0}]
        with patch.object(runtime, 'query', side_effect=query), patch.object(runtime, 'evaluate') as evaluate, patch.object(runtime.time, 'monotonic', side_effect=[0, 10]):
            with self.assertRaisesRegex(RuntimeError, 'uniquely identified'):
                runtime.dropdown(['kitty'])
        self.assertEqual(evaluate.call_count, 1)  # Spawn only. Never move/pin an arbitrary client.
        self.assertNotIn('0x123', evaluate.call_args.args[0])

    def test_dropdown_hide_uses_only_its_unique_client(self):
        identity = 'hyprflux-dropdown-' + common.runtime().name.removeprefix('hyprflux-')
        client = {'class': identity, 'address': '0x456', 'workspace': {'name': '1'}}
        def query(name):
            return [client] if name == 'clients' else [{'focused': True, 'width': 1000, 'height': 800, 'x': 0, 'y': 0}]
        with patch.object(runtime, 'query', side_effect=query), patch.object(runtime, 'evaluate') as evaluate:
            runtime.dropdown(['kitty'])
        code = evaluate.call_args.args[0]
        self.assertIn('[' + common.lua('follow') + ']=false', code)
        self.assertNotIn('pin(', code)

    def test_pid_reuse_cannot_kill_unrelated_music(self):
        common.write_json(common.runtime() / 'music.json', {'pid': 12345, 'start': 'old'})
        with patch.object(common, 'process_identity', return_value='new'), patch('os.killpg') as kill:
            common.stop_owned('music')
            kill.assert_not_called()

    def test_music_only_terminates_its_owned_process_group(self):
        with patch.object(common, 'owned_process', return_value=12345), patch('os.getpgid', return_value=12345), patch('os.killpg') as kill:
            common.stop_owned('music')
            kill.assert_called_once_with(12345, signal.SIGTERM)

    def test_wallpaper_empty_collection_is_a_clean_failure(self):
        directory = self.root / 'empty'
        directory.mkdir()
        with self.assertRaisesRegex(RuntimeError, 'No supported'):
                wallpaper.collection(directory)

    def test_wallpaper_preview_size_is_large_without_launcher_override(self):
        theme = (ROOT / '.config/rofi/config-wallpaper.rasi').read_text()
        icon = re.search(r'element-icon\s*\{([^}]+)\}', theme)[1]
        self.assertRegex(icon, r'\bsize:\s*25%;')

    def test_wallpaper_collection_filters_and_preserves_spaces(self):
        first = self.image('first/same name.png')
        second = self.image('second/same name.PNG')
        (first.parent / 'not-an-image.txt').write_text('text')
        self.assertEqual(set(wallpaper.collection(first.parent.parent)), {first, second})

    def test_wallpaper_selection_uses_exact_index_for_duplicate_names(self):
        first = self.image('first/same name.png')
        second = self.image('second/same name.png')
        with patch.object(wallpaper, 'menu', return_value=2), patch.object(wallpaper, 'focused', return_value='DP-1'), patch.object(wallpaper, 'apply') as apply:
            wallpaper.select(first.parent.parent)
            apply.assert_called_once_with(second, 'DP-1')

    def test_wallpaper_cancel_changes_nothing(self):
        path = self.image()
        with patch.object(wallpaper, 'menu', return_value=None), patch.object(wallpaper, 'apply') as apply:
            wallpaper.select(path.parent)
            apply.assert_not_called()

    def test_wallpaper_preview_uses_public_query_and_space_safe_path(self):
        path = self.image()
        text = ': DP-2: 2560x1440, scale: 1, currently displaying: image: ' + str(path) + '\n'
        with patch.object(wallpaper, 'run', return_value=result(text)):
            wallpaper.sync_preview('DP-2')
        self.assertEqual((self.hypr.parent / 'rofi/.current_wallpaper').resolve(), path)
        self.assertEqual((self.hypr / 'wallpaper_effects/.wallpaper_current').read_bytes(), b'image')

    def test_wallpaper_image_failure_does_not_persist_success(self):
        path = self.image()
        with patch.object(wallpaper, 'ensure_awww'), patch.object(wallpaper, 'run', side_effect=RuntimeError('image failed')):
            with self.assertRaises(RuntimeError):
                wallpaper.apply(path, 'DP-1')
        self.assertFalse(wallpaper.state_path().exists())

    def test_video_persistence_does_not_rewrite_lua(self):
        path = self.image("test's video.MP4")
        config = self.hypr / 'startup.lua'
        config.write_text('user custom settings')
        process = Mock()
        process.wait.side_effect = subprocess.TimeoutExpired('mpvpaper', .2)
        with patch.object(wallpaper, 'stop_owned'), patch.object(wallpaper, 'start_owned', return_value=process) as start:
            wallpaper.apply(path, 'DP-1')
        self.assertEqual(start.call_args.args[1][-1], str(path))
        self.assertEqual(common.read_json(wallpaper.state_path()), {'DP-1': str(path)})
        self.assertEqual(config.read_text(), 'user custom settings')

    def test_wallpaper_daemon_failure_is_bounded(self):
        with patch.object(wallpaper, 'run', return_value=result(returncode=1)), patch.object(wallpaper, 'detached'), patch.object(wallpaper.time, 'monotonic', side_effect=[0, 10]):
            with self.assertRaisesRegex(RuntimeError, '5 seconds'):
                wallpaper.ensure_awww()

    def test_automatic_wallpaper_failure_does_not_sleep(self):
        with patch.object(wallpaper, 'select', side_effect=RuntimeError('failed')), patch.object(wallpaper.time, 'sleep') as sleep:
            with self.assertRaises(RuntimeError):
                wallpaper.auto(self.root)
            sleep.assert_not_called()

    def test_screenshot_cancel_does_not_capture_or_create_files(self):
        with patch.object(screenshot, 'run', return_value=result(returncode=1)) as run:
            screenshot.screenshot(['--area'])
        self.assertEqual(run.call_count, 1)
        self.assertFalse((self.root / 'Pictures/Screenshots').exists())

    def test_screenshot_selector_error_is_not_treated_as_cancel(self):
        with patch.object(screenshot, 'run', return_value=result(returncode=2, stderr='broken display')):
            with self.assertRaisesRegex(RuntimeError, 'broken display'):
                screenshot.screenshot(['--area'])

    def test_screenshot_capture_failure_removes_temporary_files(self):
        def run(args, **kwargs):
            if args[0] == 'xdg-user-dir':
                return result(str(self.root / 'Pictures'))
            raise RuntimeError('capture failed')
        with patch.object(screenshot, 'run', side_effect=run):
            with self.assertRaisesRegex(RuntimeError, 'capture failed'):
                screenshot.screenshot(['--now'])
        self.assertEqual(list((self.root / 'Pictures/Screenshots').iterdir()), [])

    def test_screenshot_success_uses_safe_filename_and_exact_geometry(self):
        def run(args, **kwargs):
            if args[0] == 'xdg-user-dir':
                return result(str(self.root / 'Pictures'))
            if args[0] == 'grim':
                self.assertEqual(args[1:3], ['-g', '-10,20 300x200'])
                Path(args[-1]).write_bytes(b'png data')
            return result()
        window = {'class': '../../unsafe/app', 'at': [-10, 20], 'size': [300, 200]}
        with patch.object(screenshot, 'query', return_value=window), patch.object(screenshot, 'run', side_effect=run), patch.object(screenshot.subprocess, 'run', return_value=result()):
            screenshot.screenshot(['--active'])
        files = list((self.root / 'Pictures/Screenshots').iterdir())
        self.assertEqual(len(files), 1)
        self.assertEqual(files[0].read_bytes(), b'png data')

    def test_settings_reads_terminal_not_quoted_comment(self):
        path = self.hypr / 'UserConfigs/user-defaults.lua'
        path.parent.mkdir(parents=True)
        path.write_text('term = "kitty", -- repo default was "foot"\n')
        with patch.dict(os.environ, {'EDITOR': 'nvim --clean'}):
            self.assertEqual(settings.defaults(), (['kitty'], ['nvim', '--clean']))

    def test_preset_bad_reload_restores_previous_file(self):
        source = self.hypr / 'animations/preset.lua'
        source.parent.mkdir(parents=True)
        source.write_text('new config')
        target = self.hypr / 'UserConfigs/user-animations.lua'
        target.parent.mkdir(parents=True)
        target.write_text('original config')
        def run(args, **kwargs):
            return result('bad rule') if args == ['hyprctl', 'configerrors'] else result('ok')
        with patch.object(settings, 'menu', return_value=0), patch.object(settings, 'run', side_effect=run):
            with self.assertRaisesRegex(RuntimeError, 'bad rule'):
                settings.preset('animation')
        self.assertEqual(target.read_text(), 'original config')
        self.assertEqual(list(target.parent.iterdir()), [target])

    def test_legacy_only_monitor_profile_is_not_reported_loaded(self):
        directory = self.hypr / 'Monitor_Profiles'
        directory.mkdir()
        (directory / 'legacy.conf').write_text('monitor = old syntax')
        with self.assertRaisesRegex(RuntimeError, 'No Lua presets'):
            settings.preset('monitor')

    def test_quick_settings_hides_unavailable_theme_browser(self):
        def menu(labels, *args, **kwargs):
            self.assertNotIn('Choose Rofi Theme', labels)
            self.assertNotIn('Switch Dark-Light Theme', labels)
            return None
        with patch.object(settings.shutil, 'which', return_value=None), patch.object(settings, 'menu', side_effect=menu):
            settings.quick_settings()

    def test_update_checker_is_read_only_and_bounded(self):
        (self.hypr / 'v2.4.0').touch()
        response = Mock()
        response.read.return_value = b'[{"name":"v2.5.0"}]'
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        with patch.object(update.urllib.request, 'urlopen', return_value=response) as request:
            update.check_update()
        self.assertEqual(request.call_args.kwargs['timeout'], 15)
        update.notify.assert_called_once()
        self.assertEqual(list(self.hypr.iterdir()), [self.hypr / 'v2.4.0'])

    def test_removed_scripts_and_bindings_are_absent(self):
        for name in ('SyncBlog.sh', 'ObsidianGenerate.sh', 'notes-ai'):
            self.assertFalse((ROOT / '.config/hypr/UserScripts' / name).exists())
            for path in ('UserConfigs/user-keybinds.lua', 'scripts/KeyHints.sh'):
                self.assertNotIn(name, (ROOT / '.config/hypr' / path).read_text())

    def test_desktop_python_files_parse(self):
        for path in SCRIPTS.rglob('*.py'):
            with self.subTest(path=path.name):
                ast.parse(path.read_text(), filename=str(path))

    def test_audio_mic_decrease_and_toggle_have_valid_argv(self):
        setup = '''
pamixer() {
    case "$*" in
        *--get-volume*) echo 42;;
        *--get-mute*) echo true;;
        *) printf 'CALL'; printf '<%s>' "$@"; echo;;
    esac
}
notify-send() { :; }
export -f pamixer notify-send
bash "$1" "$2"
'''
        for flag in ('--mic-dec', '--toggle-mic'):
            with self.subTest(flag=flag):
                output = subprocess.run(['bash', '-c', setup, '_', str(SCRIPTS / 'Volume.sh'), flag], text=True, capture_output=True)
                self.assertEqual(output.returncode, 0, output.stderr)
                self.assertNotIn('<u>', output.stdout)
                self.assertIn('CALL<--default-source>', output.stdout)

    def test_service_toggle_never_launches_unmanaged_hypridle(self):
        source = (SCRIPTS / 'Hypridle.sh').read_text()
        self.assertIn('systemctl --user start hypridle.service', source)
        self.assertIn('systemctl --user stop hypridle.service', source)
        self.assertNotIn('"$PROCESS"', source)

    def test_recovery_requires_explicit_confirmation(self):
        output = subprocess.run(['bash', str(SCRIPTS / 'PortalHyprland.sh')], text=True, capture_output=True)
        self.assertEqual(output.returncode, 2)
        self.assertIn('--restart', output.stderr)

    def test_touchpad_discovers_device_and_fails_cleanly_if_absent(self):
        with patch.object(devices, 'query', return_value={'mice': []}):
            with self.assertRaisesRegex(RuntimeError, 'No touchpad'):
                devices.touchpad()
        with patch.object(devices, 'query', return_value={'mice': [{'name': 'different-laptop-touchpad'}]}), patch.object(devices, 'evaluate') as evaluate:
            devices.touchpad()
        self.assertIn(common.lua('different-laptop-touchpad'), evaluate.call_args.args[0])

    def test_preset_cancel_and_invalid_lua_leave_target_unchanged(self):
        source = self.hypr / 'animations/preset.lua'
        source.parent.mkdir(parents=True)
        source.write_text('invalid lua')
        target = self.hypr / 'UserConfigs/user-animations.lua'
        target.parent.mkdir(parents=True)
        target.write_text('original')
        with patch.object(settings, 'menu', return_value=None), patch.object(settings, 'run') as run:
            settings.preset('animation')
            run.assert_not_called()
        with patch.object(settings, 'menu', return_value=0), patch.object(settings, 'run', side_effect=RuntimeError('Lua syntax')):
            with self.assertRaises(RuntimeError):
                settings.preset('animation')
        self.assertEqual(target.read_text(), 'original')

    def test_screenshot_clipboard_failure_keeps_saved_file_and_reports_failure(self):
        def run(args, **kwargs):
            if args[0] == 'xdg-user-dir':
                return result(str(self.root / 'Pictures'))
            if args[0] == 'grim':
                Path(args[-1]).write_bytes(b'image')
            return result()
        with patch.object(screenshot, 'run', side_effect=run), patch.object(screenshot.subprocess, 'run', return_value=result(returncode=1)):
            with self.assertRaisesRegex(RuntimeError, 'clipboard failed'):
                screenshot.screenshot(['--now'])
        self.assertEqual(len(list((self.root / 'Pictures/Screenshots').glob('*.png'))), 1)

    def test_music_start_failure_has_no_stale_pid_record(self):
        process = Mock()
        process.pid = 12345
        with patch.object(common, 'detached', return_value=process), patch.object(common, 'process_identity', return_value=None):
            with self.assertRaises(RuntimeError):
                common.start_owned('music', ['mpv'])
        self.assertFalse((common.runtime() / 'music.json').exists())

    def test_wallpaper_restore_uses_saved_exact_paths_not_lua_edits(self):
        path = self.image("wallpaper's name.MP4")
        common.write_json(wallpaper.state_path(), {'DP-2': str(path)})
        with patch.object(wallpaper, 'query', return_value=[{'name': 'DP-2'}]), patch.object(wallpaper, 'ensure_awww'), patch.object(wallpaper, 'apply') as apply:
            wallpaper.restore()
        apply.assert_called_once_with(path, 'DP-2', persist=False)

    def test_sound_fallback_is_paplay(self):
        source = (SCRIPTS / 'Sounds.sh').read_text()
        self.assertNotIn('pa-play', source)
        self.assertIn('exec paplay', source)

    def test_tuned_missing_dependency_fails_without_sudo_or_install(self):
        binary = self.root / 'bin'
        binary.mkdir()
        notify = binary / 'notify-send'
        notify.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
        notify.chmod(0o755)
        output = subprocess.run(['/bin/bash', str(ROOT / '.config/hypr/UserScripts/Toggle-tuned.sh')],
                                env={**os.environ, 'PATH': str(binary)}, text=True, capture_output=True)
        self.assertEqual(output.returncode, 1)
        self.assertIn('Missing command', output.stdout)
