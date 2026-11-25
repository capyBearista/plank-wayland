# Plank Wayland — customized floating taskbar

A lightweight, application-centric Hyprland taskbar built on Quickshell. This fork preserves clear glass, opaque icons, running underlines, Walker launching, and the existing compositor focus dispatchers. It does not replace Waybar, Darkman, Mako or your window manager.

## Status and requirements

- Hyprland 0.57 Lua dispatchers, Wayland, Quickshell, Qt 6 Quick, Python 3 and util-linux (flock).
- The pre-refactor fork was exercised on Fedora 45 with Hyprland 0.57.2 and Fedora Quickshell 0.2.1 (git build). Upstream advertised >=0.3.0. The new code targets documented 0.2.1 APIs; live acceptance testing is still required. Do not upgrade solely to satisfy the upstream README.
- Walker integration defaults to the existing `~/.local/bin/walker-themed` wrapper. Other installations may set `dock.launcherCommand` to their own argument array.
- All changes are user-level. No Hyprland, Waybar, VPN or global appearance config is edited by the installer.

## Upgrade existing checkout — preserve settings and pins FIRST

The old dock stored mutable settings and pins in the Git checkout. This version uses XDG files, and tracked pins are now empty. Stop the old dock using Ctrl-C in its launch terminal (or stop its existing service if one exists). Run these commands in Bash:

```bash
cd ~/plank-wayland
legacy="$(mktemp -d "$HOME/plank-wayland-legacy.XXXXXX")"
cp -p settings.js apps.js "$legacy/"
printf 'Legacy backup: %s\n' "$legacy"
git status --short
# Stash only legacy user data if it is modified. Do not pop this stash into the new source.
git stash push -m "legacy dock user data" -- settings.js apps.js
git pull --ff-only origin main
./install.sh --legacy-dir "$legacy"
./tests/run.sh
./run.sh
```

Stop if the pull fails or other local changes conflict. Do not reset your checkout. The installer never overwrites existing XDG data; if you already initialized empty pins, back up the XDG files and reconcile them before migrating. Keep the legacy backup and stash until you verify pins and settings. Do not push your old personal data.

Fresh install:

```bash
git clone https://github.com/capyBearista/plank-wayland.git ~/plank-wayland
cd ~/plank-wayland
./install.sh
./run.sh
```

## Behavior

| Action | Result |
| --- | --- |
| Move pointer to bottom edge | Reveal dock |
| Click a running single-window app | Focus or minimize according to workspace and mode |
| Click a pinned app with no window | Launch; pending indicator times out |
| Click or hover a multi-window app | Show window picker |
| Right-click app | Context menu, pin/unpin, settings |
| Right-click empty dock background | Settings |
| Drag a pinned icon and drop | Reorder pins; launcher stays fixed |
| Click launcher | Invoke configured Walker command |
| Window requests urgency | Highlight app, briefly reveal on its monitor (not over fullscreen by default) |

## Configuration

Data lives at `${XDG_CONFIG_HOME:-$HOME/.config}/plank-wayland/`:
- `settings.json` — validated runtime settings; edit directly or use the panel.
- `pinned-apps.json` — ordered user pins; not committed.
- `migration-backup/` — legacy input backups (when migration requested).

See [configuration reference](docs/configuration.md). Dock uses the existing Darkman mode file at `${XDG_CONFIG_HOME:-$HOME/.config}/desktop-theme/mode`; it only reads it. Set `themeMode` to manual for a fixed preset.

The Hyprland layer namespace is `plank-wayland-dock` on every display. Existing Altair blur rule matches it. Auto-hide reserves zero screen space. Repeated monitor names are not hardcoded.

### Experimental minimize / restore

Default `minimizeMode: "off"` preserves proven focus behavior. Try `"native"` first: the Wayland minimize request can be ignored by Hyprland. If not supported, opt into `"workspace"` mode. That moves an ordinary numeric-workspace window in the currently focused workspace to `special:plank-minimized-N--MONITOR` where N is its original workspace number and MONITOR is its original display (when known). Clicking its taskbar icon restores the window to N, preferring the original display when that workspace no longer exists. Named, fullscreen and pinned windows are not moved; grouped apps retain the picker. If a workspace or monitor was moved/disconnected, current topology takes precedence. No fallback runs automatically.

Recovery even if the dock crashes: open the special workspace from a Hyprland terminal (replace the example name with the exact special-workspace name from hyprctl clients, without its special: prefix), then move the window back using your normal keybinding:

```bash
hyprctl clients
hyprctl dispatch 'hl.dsp.workspace.toggle_special("plank-minimized-1--eDP-1")'
```

Or restore a specific window by replacing the example address and workspace:

```bash
hyprctl dispatch 'hl.dsp.window.move({ window = "address:0xEXAMPLE", workspace = "1", follow = true })'
```

Do not enable workspace mode until you have tested restoration with a disposable window. Before rolling back to the old dock, restore all windows in these special workspaces.

## Optional Hyprland/UWSM autostart

First test the manual instance. Stop it, then run:

```bash
./install.sh --enable-service
systemctl --user status plank-wayland.service
journalctl --user -u plank-wayland.service -b --no-pager
```

The user service is tied to graphical-session.target (UWSM), has a Hyprland socket/environment guard, and uses the repository's run.sh. Do not add a duplicate Hyprland autostart command. The runtime lock prevents two new instances on the same Hyprland session; it cannot stop an old pre-upgrade instance.

Disable/remove the service and return to manual startup:

```bash
./install.sh --disable-service
./run.sh
```

This preserves user settings and pins. No system service or sudo required.

## Tests

```bash
./tests/run.sh
```

Bash syntax checks, Python migration tests and optional Node-based JavaScript logic tests are separate from the graphical acceptance checks. See [runtime acceptance](docs/runtime-acceptance.md). The new dock is not certified on Altair until those checks pass.

## Rollback

Stop the new dock and disable its user service if enabled. Restore minimized windows first. To inspect the old baseline without changing your main branch, use a separate worktree at `7cb2fd2` and copy your saved legacy settings and pins there. Keep new XDG files; the old version does not use them. Never overwrite user settings with repository defaults just to test.

Upstream: [franklinbravos/plank-wayland](https://github.com/franklinbravos/plank-wayland). API references: [Quickshell 0.2.1](https://quickshell.org/docs/v0.2.1/), [Hyprland dispatchers](https://wiki.hypr.land/0.57.0/configuring/core/dispatchers/), [UWSM](https://wiki.hypr.land/useful-utilities/uwsm/).
