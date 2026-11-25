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

    def test_legacy_settings_preserve_custom_values(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            legacy = folder / "legacy"
            legacy.mkdir()
            (legacy / "settings.js").write_text('var dock = {"iconSize":48,"autoHide":false}\nvar styleName = "custom"\nvar uiLanguage = "en"\nvar styles = {"custom":{"indicatorStyle":"dot"}}\n')
            (legacy / "apps.js").write_text('var items = [{"appId":"test","command":["example"]}]')
            module.initialize(folder / "config", legacy)
            data = json.loads((folder / "config/settings.json").read_text())
            self.assertEqual(data["dock"]["iconSize"], 48)
            self.assertFalse(data["dock"]["autoHide"])
            self.assertEqual(data["dock"]["themeMode"], "manual")
            self.assertEqual(data["dock"]["bottomGap"], 12)
            self.assertTrue((folder / "config/migration-backup/settings.js").exists())

    def test_invalid_pins_do_not_initialize(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            legacy = folder / "legacy"
            legacy.mkdir()
            (legacy / "apps.js").write_text('var items = [{"appId":""}]')
            with self.assertRaises(ValueError):
                module.initialize(folder / "config", legacy)
            self.assertFalse((folder / "config/settings.json").exists())
            self.assertFalse((folder / "config/pinned-apps.json").exists())
