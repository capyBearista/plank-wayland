#!/usr/bin/env python3
"""Initialize XDG data; migrate trusted legacy JSON-valued JS without executing it."""
import argparse
import json
import os
import re
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def value(source, name):
    match = re.search(r"(?m)^var " + re.escape(name) + r"\s*=\s*", source)
    if not match:
        raise ValueError("missing " + name)
    return json.JSONDecoder().raw_decode(source[match.end():])[0]

def write_new(path, data):
    if path.exists():
        return False
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix=".migration-")
    try:
        with os.fdopen(fd, "w") as handle:
            json.dump(data, handle, indent=4)
            handle.write("\n")
        try:
            os.link(temp, path)
        except FileExistsError:
            return False
        return True
    finally:
        os.unlink(temp)

def initialize(config_dir, legacy=None):
    config_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    defaults = (ROOT / "settings.js").read_text()
    legacy_settings = legacy / "settings.js" if legacy else None
    legacy_apps = legacy / "apps.js" if legacy else None
    source = legacy_settings.read_text() if legacy_settings and legacy_settings.is_file() else defaults
    dock = value(defaults, "dock")
    dock.update(value(source, "dock"))
    style = value(source, "styleName")
    overrides = {}
    if source != defaults:
        old_styles = value(source, "styles")
        default_styles = value(defaults, "styles")
        overrides = {key: val for key, val in old_styles.items() if default_styles.get(key) != val}
    settings = {"schemaVersion": 1, "dock": dock, "styleName": style,
                "uiLanguage": value(source, "uiLanguage"), "indicatorStyle": value(source, "styles").get(style, {}).get("indicatorStyle", "line"),
                "styleOverrides": overrides}
    pins = value(legacy_apps.read_text(), "items") if legacy_apps and legacy_apps.is_file() else []
    if not isinstance(pins, list) or any(not isinstance(p, dict) or not isinstance(p.get("appId"), str) or not p["appId"] for p in pins):
        raise ValueError("Invalid legacy pins")
    if legacy:
        backup = config_dir / "migration-backup"
        backup.mkdir(exist_ok=True, mode=0o700)
        for original in (legacy_settings, legacy_apps):
            if original and original.is_file():
                try:
                    with (backup / original.name).open("x") as out:
                        out.write(original.read_text())
                except FileExistsError:
                    pass
    for path, data in ((config_dir / "settings.json", settings), (config_dir / "pinned-apps.json", pins)):
        if write_new(path, data):
            print("Created", path)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--legacy-dir", type=Path)
    parser.add_argument("--config-dir", type=Path, default=Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "plank-wayland")
    args = parser.parse_args()
    initialize(args.config_dir, args.legacy_dir)

if __name__ == "__main__":
    main()
