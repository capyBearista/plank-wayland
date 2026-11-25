import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("configure", Path(__file__).resolve().parents[1] / "scripts/configure.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class ConfigureTests(unittest.TestCase):
    def test_init_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            module.initialize(folder)
            self.assertEqual(json.loads((folder / "pinned-apps.json").read_text()), [])
            (folder / "pinned-apps.json").write_text('[{"appId":"test"}]')
            module.initialize(folder)
            self.assertEqual(json.loads((folder / "pinned-apps.json").read_text()), [{"appId":"test"}])

    def test_legacy_pin_migration(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            legacy = folder / "legacy"
            legacy.mkdir()
            (legacy / "apps.js").write_text('.pragma library\nvar items = [{"appId":"one"},{"appId":"two"}]')
            module.initialize(folder / "config", legacy)
            pins = json.loads((folder / "config/pinned-apps.json").read_text())
            self.assertEqual([p["appId"] for p in pins], ["one","two"])
            self.assertTrue((folder / "config/migration-backup/apps.js").exists())
