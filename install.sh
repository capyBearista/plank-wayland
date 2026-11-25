#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
legacy=""
enable=0
disable=0
while (( $# )); do
  case "$1" in
    --legacy-dir) [[ $# -ge 2 ]] || { echo "Missing legacy directory" >&2; exit 2; }; legacy="$2"; shift 2 ;;
    --enable-service) enable=1; shift ;;
    --disable-service) disable=1; shift ;;
    --help) echo "Usage: ./install.sh [--legacy-dir DIRECTORY] [--enable-service | --disable-service]"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done
if (( enable && disable )); then echo "Choose one service action" >&2; exit 2; fi
if (( disable )); then
  systemctl --user disable --now plank-wayland.service
  rm -f -- "$config/systemd/user/plank-wayland.service"
  systemctl --user daemon-reload
  echo "Service removed; user data retained."
  exit 0
fi
for cmd in quickshell python3 flock; do
  command -v "$cmd" >/dev/null || { echo "Required command missing: $cmd" >&2; exit 1; }
done
quickshell --version
if [[ -n "$legacy" ]]; then
  [[ -d "$legacy" && -f "$legacy/settings.js" && -f "$legacy/apps.js" ]] || { echo "Legacy directory must contain settings.js and apps.js" >&2; exit 1; }
  python3 "$root/scripts/configure.py" --legacy-dir "$legacy"
else
  python3 "$root/scripts/configure.py"
fi
if (( enable )); then
  "$root/scripts/check-session.sh" || { echo "Enable the service from your running Hyprland session." >&2; exit 1; }
  systemctl --user is-active --quiet graphical-session.target || { echo "UWSM graphical session target is not active." >&2; exit 1; }
  mkdir -p -- "$config/systemd/user"
  python3 - "$root" "$config/systemd/user/plank-wayland.service" <<'PY'
import os, sys, tempfile
from pathlib import Path
root, destination = map(Path, sys.argv[1:])
def quote(path):
    return '"' + str(path).replace('\\', '\\\\').replace('"', '\\"').replace('%', '%%').replace('$', '$$') + '"'
unit = (root / "systemd/plank-wayland.service").read_text()
unit = unit.replace("@CHECK_SESSION@", quote(root / "scripts/check-session.sh")).replace("@RUN_SCRIPT@", quote(root / "run.sh"))
fd, path = tempfile.mkstemp(dir=destination.parent)
try:
    with os.fdopen(fd, "w") as handle:
        handle.write(unit)
    os.chmod(path, 0o644)
    os.replace(path, destination)
finally:
    if os.path.exists(path):
        os.unlink(path)
PY
  systemctl --user daemon-reload
  systemctl --user enable --now plank-wayland.service
  echo "Check status: systemctl --user status plank-wayland.service"
else
  echo "Configuration ready. Start manually: $root/run.sh"
fi
