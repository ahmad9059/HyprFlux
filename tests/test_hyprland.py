"""Hyprland runtime regressions without controlling the host compositor."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HYPR = ROOT / '.config/hypr'


class HyprlandTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('luac'), 'Lua compiler required')
    def test_all_lua_files_parse(self):
        for path in HYPR.rglob('*.lua'):
            with self.subTest(path=path.relative_to(HYPR)):
                result = subprocess.run(['luac', '-p', str(path)], text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)

    @unittest.skipUnless(shutil.which('lua'), 'Lua interpreter required')
    def test_bindings_and_workspace_callbacks(self):
        # Extract the exact argument passed to hyprctl, without contacting it.
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            stub = directory / 'hyprctl'
            stub.write_text('#!/bin/sh\n[ "$1" = eval ] || exit 1\nprintf "%s" "$2"\n')
            stub.chmod(0o755)
            result = subprocess.run(
                ['bash', str(HYPR / 'scripts/ChangeLayout.sh')],
                env={**os.environ, 'PATH': str(directory) + os.pathsep + os.environ['PATH']},
                text=True, capture_output=True, check=True)
            script = directory / 'cycle.lua'
            script.write_text(result.stdout)
            subprocess.run(['lua', str(ROOT / 'tests/hyprland_harness.lua'),
                            str(ROOT), str(script)], check=True, capture_output=True, text=True)

    def test_idle_shell_commands_and_dpms_argument(self):
        text = (HYPR / 'hypridle.conf').read_text()
        self.assertRegex(text, r'(?m)^\s*inhibit_sleep\s*=\s*3\b')
        dpms = []
        for line in text.splitlines():
            line = line.strip().removeprefix('#').strip()
            match = re.match(r'(?:lock_cmd|before_sleep_cmd|after_sleep_cmd|on-timeout|on-resume)\s*=\s*(.*)', line)
            if not match:
                continue
            # Config comments do not form part of the command.
            command = match[1].split(' #', 1)[0].strip()
            result = subprocess.run(['sh', '-n', '-c', command], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, command + '\n' + result.stderr)
            if 'hyprctl dispatch' in command:
                dpms.append(command.split('hyprctl dispatch ', 1)[1])
        self.assertEqual(len(dpms), 5)
        # Function stub checks shell argument boundaries; no real IPC calls.
        for expression in dpms:
            result = subprocess.run(
                ['sh', '-c', 'hyprctl() { [ "$#" -eq 2 ] || exit 1; printf "%s" "$2"; }; '
                 'hyprctl dispatch ' + expression], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertRegex(result.stdout, r'^hl\.dsp\.dpms\(\{ action = "(?:on|off)" \}\)$')

    def test_telegram_launches_only_the_available_preferred_client(self):
        text = (HYPR / 'UserConfigs/user-keybinds.lua').read_text()
        command = re.search(r'hl\.dsp\.exec_cmd\("([^"]+)"\), \{ description = "Telegram"', text)[1]
        for preferred in (True, False):
            with tempfile.TemporaryDirectory() as temp:
                directory = Path(temp)
                for name in ('64gram-desktop', 'telegram-desktop'):
                    if name == '64gram-desktop' and not preferred:
                        continue
                    client = directory / name
                    client.write_text('#!/bin/sh\nprintf "%s" "' + name + '"\n')
                    client.chmod(0o755)
                result = subprocess.run(['/bin/sh', '-c', command], text=True,
                                        capture_output=True, env={**os.environ, 'PATH': temp})
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, '64gram-desktop' if preferred else 'telegram-desktop')

    def test_dispatcher_moves_never_embed_silent_in_workspace(self):
        for name in ('configs/keybinds.lua', 'scripts/Dropterminal.sh'):
            for line in (HYPR / name).read_text().splitlines():
                if 'hl.dsp.window.move' in line:
                    self.assertNotIn(' silent', line, name)

    def test_refresh_uses_existing_wallpaper_helper(self):
        text = (HYPR / 'scripts/RefreshNoWaybar.sh').read_text()
        self.assertNotIn('WallpaperSwww.sh', text)
        self.assertIn('"${SCRIPTSDIR}/WallpaperAwww.sh"', text)
        self.assertTrue((HYPR / 'scripts/WallpaperAwww.sh').is_file())

    def test_hypr_mirror_matches_including_symlinks(self):
        mirror = ROOT / 'base-dots/config/hypr'
        def entries(root):
            return {str(p.relative_to(root)): ('link', str(p.readlink())) if p.is_symlink()
                    else ('file', p.read_bytes())
                    for p in root.rglob('*') if p.is_symlink() or p.is_file()}
        self.assertEqual(entries(HYPR), entries(mirror))
