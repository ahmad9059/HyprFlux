"""Read-only sleep-lab reporting tests. Never request suspend or hibernate."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'utilities/sleep-lab.sh'


class SleepLabTests(unittest.TestCase):
    def test_shell_syntax(self):
        subprocess.run(['bash', '-n', str(SCRIPT)], check=True, capture_output=True)

    def test_missing_log_is_not_reported_as_a_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = subprocess.run(['bash', str(SCRIPT), 'status'], capture_output=True, text=True,
                                    env={**os.environ, 'SLEEP_LAB_LOG': tmp + '/missing'})
        self.assertEqual(result.returncode, 0)
        self.assertIn('No sleep tests recorded', result.stdout)
        self.assertNotIn('PASS', result.stdout)

    def test_missing_end_record_means_incomplete_not_proven_hang(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            (base / 'suspend_stats').mkdir()
            (base / 'mem_sleep').write_text('s2idle [deep]\n')
            (base / 'suspend_stats/last_hw_sleep').write_text('0\n')
            log = base / 'log'
            log.write_text('2026-11-08T11:00:00\tSTART 100 state=disk\n'
                           '2026-11-08T11:05:00\tEND 100 verdict=RESUMED_NEEDS_USER_CHECK slept=300s\n'
                           '2026-11-08T11:10:00\tSTART 200 state=mem\n')
            result = subprocess.run(['bash', str(SCRIPT), 'status'], capture_output=True, text=True,
                                    env={**os.environ, 'SLEEP_LAB_LOG': str(log), 'SLEEP_LAB_POWER': tmp})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('RESUMED_NEEDS_USER_CHECK', result.stdout)
        self.assertIn('INCOMPLETE 200', result.stdout)
        self.assertNotIn('HUNG', result.stdout)

    def test_test_arguments_are_rejected_before_any_power_operation(self):
        for args in (['-s', 'oops'], ['-S', 'bad-state'], ['-D', 'bad-mode'], ['-p', 'bad-level']):
            result = subprocess.run(['bash', str(SCRIPT), 'test', *args], capture_output=True, text=True)
            self.assertEqual(result.returncode, 2, (args, result.stdout, result.stderr))

    def test_resume_alone_is_never_an_automatic_full_success(self):
        text = SCRIPT.read_text()
        self.assertNotIn('verdict="PASS"', text)
        self.assertIn('kernel-resume-failures=', text)
        self.assertIn('kernel-driver-errors', text)
