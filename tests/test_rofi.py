"""Rofi themes and cancel/failure workflows; never touch real clipboard or projects."""
import contextlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / '.config/hypr/scripts'))
from hyprflux import rofi


def result(stdout='', code=0, stderr=''):
    return subprocess.CompletedProcess([], code, stdout, stderr)


class RofiTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.hypr = self.home / '.config/hypr'
        self.hypr.mkdir(parents=True)
        runtime = self.home / 'runtime'
        runtime.mkdir(mode=0o700)
        self.stack = contextlib.ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(patch.dict(os.environ, {'HOME': str(self.home), 'XDG_RUNTIME_DIR': str(runtime), 'HYPRLAND_INSTANCE_SIGNATURE': 'rofi-test'}))
        self.stack.enter_context(patch.object(rofi, 'HYPR', self.hypr))
        self.stack.enter_context(patch.object(rofi, 'notify'))

    def emoji_data(self):
        path = self.hypr / 'scripts/data/emoji.txt'
        path.parent.mkdir(parents=True)
        path.write_text('😀 grinning face\n👨‍💻 man technologist\n')

    def test_cancel_emoji_never_writes_clipboard(self):
        self.emoji_data()
        with patch.object(rofi, 'pick', return_value=None), patch.object(rofi, 'clipboard_copy') as copy:
            rofi.emoji()
            copy.assert_not_called()

    def test_emoji_index_preserves_multi_codepoint_sequence(self):
        self.emoji_data()
        with patch.object(rofi, 'pick', return_value=1), patch.object(rofi, 'clipboard_copy') as copy:
            rofi.emoji()
            copy.assert_called_once_with('👨‍💻'.encode())

    def test_dialog_cancel_and_error_are_different(self):
        with patch.object(rofi, 'run', return_value=result(code=1)):
            self.assertIsNone(rofi.pick(['row'], 'test'))
        with patch.object(rofi, 'run', return_value=result(code=2, stderr='theme failed')) as run:
            with self.assertRaisesRegex(RuntimeError, 'theme failed'):
                rofi.pick(['row'], 'test')
            self.assertEqual(run.call_count, 1)

    def test_invalid_index_is_never_treated_as_typed_path(self):
        for value in ('../outside', '-1', '200'):
            with self.subTest(value=value), patch.object(rofi, 'run', return_value=result(value)):
                with self.assertRaises(RuntimeError):
                    rofi.pick(['only one'], 'test')

    def test_single_dialog_lock_does_not_kill_existing_menu(self):
        with rofi.session() as first:
            self.assertTrue(first)
            with patch.object(rofi, 'run') as run:
                self.assertIsNone(rofi.pick(['another'], 'test'))
                run.assert_not_called()

    def test_row_newlines_cannot_change_selection_mapping(self):
        with patch.object(rofi, 'run', return_value=result('0')) as run:
            self.assertEqual(rofi.pick(['file\nwith newline'], 'test'), 0)
        self.assertEqual(run.call_args.kwargs['input'], 'file with newline\n')

    def test_messages_are_markup_escaped(self):
        with patch.object(rofi, 'run', return_value=result(code=1)) as run:
            rofi.dialog([], 'test', free_text=True, message='2 < 3 & 4 > 1')
        args = run.call_args.args[0]
        self.assertEqual(args[args.index('-mesg') + 1], '2 &lt; 3 &amp; 4 &gt; 1')
        self.assertNotIn('-no-custom', args)

    def test_clipboard_cancel_is_read_only(self):
        with patch.object(rofi, 'run', return_value=result('7\tentry\n')) as run, patch.object(rofi, 'dialog', return_value=None), patch.object(rofi, 'clipboard_copy') as copy:
            rofi.clipboard()
        run.assert_called_once_with(['cliphist', 'list'])
        copy.assert_not_called()

    def test_clipboard_rofi_failure_does_not_loop(self):
        with patch.object(rofi, 'run', return_value=result('7\tentry\n')), patch.object(rofi, 'dialog', side_effect=RuntimeError('rofi failed')) as dialog:
            with self.assertRaises(RuntimeError):
                rofi.clipboard()
            self.assertEqual(dialog.call_count, 1)

    def test_decode_failure_and_empty_result_preserve_current_clipboard(self):
        for decoded in (result(code=1), result('')):
            with patch.object(rofi, 'run', return_value=result('7\tentry\n')), patch.object(rofi, 'dialog', return_value=(0, '0')), patch.object(rofi.subprocess, 'run', return_value=decoded), patch.object(rofi, 'clipboard_copy') as copy:
                with self.assertRaisesRegex(RuntimeError, 'left unchanged'):
                    rofi.clipboard()
                copy.assert_not_called()

    def test_clipboard_delete_uses_exact_original_selected_row(self):
        with patch.object(rofi, 'run', side_effect=[result('7\tfirst\n8\tsecond\n'), result(), result()]) as run, patch.object(rofi, 'dialog', return_value=(10, '1')):
            rofi.clipboard()
        self.assertEqual(run.call_args_list[1].args[0], ['cliphist', 'delete'])
        self.assertEqual(run.call_args_list[1].kwargs['input'], '8\tsecond\n')

    def test_history_wipe_requires_explicit_confirmation(self):
        with patch.object(rofi, 'run', return_value=result('7\tentry\n')) as run, patch.object(rofi, 'dialog', side_effect=[(11, ''), None]), patch.object(rofi, 'pick', return_value=0):
            rofi.clipboard()
        self.assertFalse(any(call.args[0] == ['cliphist', 'wipe'] for call in run.call_args_list))
        with patch.object(rofi, 'run', side_effect=[result('7\tentry\n'), result(), result()]) as run, patch.object(rofi, 'dialog', return_value=(11, '')), patch.object(rofi, 'pick', return_value=1):
            rofi.clipboard()
        self.assertEqual(run.call_args_list[1].args[0], ['cliphist', 'wipe'])

    def test_clipboard_copier_does_not_capture_daemon_pipes(self):
        with patch.object(rofi.subprocess, 'run', return_value=result()) as run:
            rofi.clipboard_copy(b'not real clipboard data')
        self.assertEqual(run.call_args.kwargs['stdout'], subprocess.DEVNULL)
        self.assertEqual(run.call_args.kwargs['stderr'], subprocess.DEVNULL)
        self.assertNotIn('capture_output', run.call_args.kwargs)
        with self.assertRaises(RuntimeError):
            rofi.clipboard_copy(b'')

    def test_calculator_failure_does_not_copy_error_text(self):
        with patch.object(rofi, 'dialog', side_effect=[(0, 'bad expression'), None]), patch.object(rofi, 'run', return_value=result(code=1, stderr='bad expression')), patch.object(rofi, 'clipboard_copy') as copy:
            rofi.calculator()
            copy.assert_not_called()

    def test_calculator_success_uses_argv_and_copies_result(self):
        with patch.object(rofi, 'dialog', side_effect=[(0, '1+1'), None]), patch.object(rofi, 'run', return_value=result('2\n')) as run, patch.object(rofi, 'clipboard_copy') as copy:
            rofi.calculator()
        run.assert_called_once_with(['qalc', '-t', '--', '1+1'], check=False, timeout=15)
        copy.assert_called_once_with(b'2')

    def test_project_names_are_environment_data_not_shell_source(self):
        path = self.home / 'Documents/Projects/$(touch owned)'
        path.mkdir(parents=True)
        tmuxifier = self.home / '.tmuxifier/bin/tmuxifier'
        tmuxifier.parent.mkdir(parents=True)
        tmuxifier.write_text('#!/bin/sh\nexit 0\n')
        tmuxifier.chmod(0o755)
        with patch.object(rofi, 'pick', return_value=0), patch.object(rofi.shutil, 'which', return_value='/usr/bin/kitty'), patch.object(rofi, 'detached') as launch:
            rofi.projects()
        command = launch.call_args.args[0]
        self.assertNotIn('-lc', command)
        self.assertNotIn('-c', command)
        self.assertEqual(launch.call_args.kwargs['env']['PROJECT_DIR'], str(path))
        self.assertEqual(command[-3:], [str(tmuxifier), 'load-session', 'web-dev'])

    def test_project_cancel_never_launches_terminal(self):
        (self.home / 'Documents/Projects/project').mkdir(parents=True)
        with patch.object(rofi, 'pick', return_value=None), patch.object(rofi, 'detached') as launch:
            rofi.projects()
        launch.assert_not_called()

    def test_clone_cancel_never_runs_git(self):
        with patch.object(rofi, 'run', side_effect=[result('owner'), result('[{"nameWithOwner":"owner/repo"}]')]) as run, patch.object(rofi, 'pick', return_value=None):
            rofi.clone_repository()
        self.assertTrue(all(call.args[0][0] == 'gh' for call in run.call_args_list))

    def test_clone_rejects_path_traversal(self):
        for name in ('owner/../escape', 'owner/..'):
            with patch.object(rofi, 'run', side_effect=[result('owner'), result(json.dumps([{'nameWithOwner': name}]))]) as run, patch.object(rofi, 'pick', return_value=0):
                with self.assertRaisesRegex(RuntimeError, 'Invalid repository'):
                    rofi.clone_repository()
            self.assertFalse(any(call.args[0][0] == 'git' for call in run.call_args_list))

    def test_keybinds_do_not_invent_code_zero(self):
        rows = rofi.binding_rows([{'key': '', 'keycode': 0, 'modmask': 64, 'description': 'Workspace 1'},
                                 {'key': '', 'keycode': 10, 'dispatcher': '__lua'}])
        self.assertIn('[keycode unavailable]', rows[0])
        self.assertIn('Workspace 1', rows[0])
        self.assertIn('code:10', rows[1])
        self.assertNotIn('code:0', '\n'.join(rows))

    def test_main_launcher_preserves_other_menus_and_has_no_captured_pipes(self):
        with patch.object(rofi.subprocess, 'run', return_value=result(code=1)) as run:
            rofi.launcher()
        self.assertNotIn('pkill', run.call_args.args[0])
        self.assertEqual(run.call_args.kwargs['stdout'], subprocess.DEVNULL)

    def test_music_cancel_does_not_stop_playback(self):
        from hyprflux import runtime
        with patch.object(rofi, 'pick', return_value=None), patch.object(runtime, 'music') as music:
            rofi.music_menu()
        music.assert_not_called()

    def test_music_failure_is_not_announced_as_success(self):
        from hyprflux import runtime
        data = self.hypr / 'scripts/data/radio-stations.json'
        data.parent.mkdir(parents=True)
        data.write_text('{"Station":"https://example.invalid/stream"}')
        with patch.object(rofi, 'pick', side_effect=[0, 0]), patch.object(runtime, 'music', side_effect=RuntimeError('spawn failed')):
            with self.assertRaises(RuntimeError):
                rofi.music_menu()
        rofi.notify.assert_not_called()

    def test_theme_property_names_and_resource_migration(self):
        for path in (ROOT / '.config/rofi').glob('*.rasi'):
            self.assertNotRegex(path.read_text(), r'\bcolums\s*:|\benable\s*:')
        data = ROOT / '.config/hypr/scripts/data'
        self.assertGreater(len((data / 'emoji.txt').read_text().splitlines()), 1800)
        self.assertEqual(len(json.loads((data / 'radio-stations.json').read_text())), 22)

    @unittest.skipUnless(shutil.which('rofi'), 'Real Rofi parser required')
    def test_all_themes_parse_with_isolated_home_and_no_display(self):
        # -dump-theme parses imports without opening a menu or reading user themes.
        config = self.home / '.config/rofi'
        shutil.copytree(ROOT / '.config/rofi', config, symlinks=True)
        env = {k: v for k, v in os.environ.items() if k not in ('DISPLAY', 'WAYLAND_DISPLAY')}
        env['XDG_CONFIG_HOME'] = str(self.home / '.config')
        for path in sorted(config.glob('*.rasi')):
            with self.subTest(theme=path.name):
                output = subprocess.run(['rofi', '-config', str(path), '-dump-theme'], env=env, capture_output=True, text=True, timeout=10)
                self.assertEqual(output.returncode, 0, output.stderr)
                self.assertEqual(output.stderr.strip(), '')

    def test_no_broad_process_kills_in_managed_entrypoints(self):
        names = ['scripts/KeyHints.sh', 'scripts/KeyBinds.sh', 'scripts/RofiEmoji.sh', 'scripts/ClipManager.sh',
                 'scripts/Launcher.sh', 'UserScripts/RofiCalc.sh', 'UserScripts/TmuxifierProjects.sh', 'UserScripts/GitRepoClone.sh']
        for name in names:
            self.assertNotIn('pkill', (ROOT / '.config/hypr' / name).read_text())
