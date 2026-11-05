"""The isolated checker must propagate invalid config, never retry into success."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('Hyprland'), 'Hyprland is installed in config-check CI')
class ConfigVerifierTests(unittest.TestCase):
    def test_valid_config_then_invalid_config(self):
        # CI checkouts are traversable by nobody; do not expose a private home.
        if not all(p.stat().st_mode & 0o005 == 0o005 for p in (ROOT, *ROOT.parents) if p != Path('/')):
            self.skipTest('Source directory is private; isolated container test required')
        good = subprocess.run(['bash', str(ROOT / 'scripts/verify-hyprland-config.sh')],
                              text=True, capture_output=True, timeout=30)
        self.assertEqual(good.returncode, 0, good.stdout + good.stderr)
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            directory.chmod(0o755)
            config = directory / 'invalid.lua'
            config.write_text('error("HYPRFLUX_EXPECTED_INVALID_CONFIG")\n')
            config.chmod(0o644)
            bad = subprocess.run(['bash', str(ROOT / 'scripts/verify-hyprland-config.sh'), str(config)],
                                 text=True, capture_output=True, timeout=30)
            self.assertNotEqual(bad.returncode, 0)
            self.assertNotIn(bad.returncode, (-11, 139), bad.stdout + bad.stderr)
            self.assertIn('HYPRFLUX_EXPECTED_INVALID_CONFIG', bad.stdout + bad.stderr)
