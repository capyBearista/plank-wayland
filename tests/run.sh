#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname -- "$0")/.."
for script in run.sh install.sh scripts/check-session.sh tests/run.sh; do bash -n "$script"; done
python3 -m unittest discover -s tests -p 'test_*.py' -v
if command -v node >/dev/null; then
  node tests/test_logic.js
else
  echo "Node not installed; JavaScript tests skipped." >&2
fi
