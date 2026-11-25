#!/usr/bin/env bash
set -euo pipefail

script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
project_dir="$(cd -- "$(dirname -- "$script_path")" && pwd)"

command -v quickshell >/dev/null || { echo "Quickshell is required" >&2; exit 1; }
command -v python3 >/dev/null || { echo "Python 3 is required" >&2; exit 1; }
command -v flock >/dev/null || { echo "flock (util-linux) is required" >&2; exit 1; }
"$project_dir/scripts/check-session.sh" || { echo "Start this dock from a Hyprland Wayland session." >&2; exit 1; }
python3 "$project_dir/scripts/configure.py"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/plank-wayland"

follow_icon_theme_enabled() {
  python3 - "$config_dir/settings.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    sys.exit(0 if json.load(f).get("dock", {}).get("followSystemIconTheme", True) else 1)
PY
}

detect_icon_theme() {
  local file line in_icons

  for file in \
    "$HOME/.config/gtk-3.0/settings.ini" \
    "$HOME/.config/gtk-4.0/settings.ini"; do
    [[ -r "$file" ]] || continue
    while IFS= read -r line; do
      if [[ "$line" =~ ^[[:space:]]*gtk-icon-theme-name[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
      fi
    done < "$file"
  done

  file="$HOME/.config/kdeglobals"
  if [[ -r "$file" ]]; then
    in_icons=0
    while IFS= read -r line; do
      [[ "$line" == "[Icons]" ]] && { in_icons=1; continue; }
      [[ "$line" == \[* ]] && in_icons=0
      if [[ "$in_icons" == 1 && "$line" =~ ^[[:space:]]*Theme[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
      fi
    done < "$file"
  fi
}

if follow_icon_theme_enabled && [[ -z "${QS_ICON_THEME:-}" ]]; then
  icon_theme="$(detect_icon_theme || true)"
  if [[ -n "$icon_theme" ]]; then
    export QS_ICON_THEME="$icon_theme"
  fi
fi

lock_path="${XDG_RUNTIME_DIR:?Missing XDG_RUNTIME_DIR}/plank-wayland-${HYPRLAND_INSTANCE_SIGNATURE}.lock"
# Keep the lock descriptor open across exec, and explain conflicts.
exec 9>"$lock_path"
if ! flock --nonblock 9; then
  echo "Plank Wayland already holds the lock for this Hyprland session. Stop the other instance before retrying." >&2
  exit 75
fi
exec quickshell --path "$project_dir/shell.qml"
