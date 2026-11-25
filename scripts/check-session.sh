#!/usr/bin/env bash
set -euo pipefail
[[ -n "${WAYLAND_DISPLAY:-}" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" && -n "${XDG_RUNTIME_DIR:-}" ]]
[[ "${HYPRLAND_INSTANCE_SIGNATURE}" =~ ^[a-zA-Z0-9_.-]+$ ]]
[[ -S "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock" ]]
