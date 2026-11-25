# Runtime acceptance — run on Altair

This is a test checklist, not a deployment record. Start the dock manually and keep the terminal logs.

- [ ] Run tests/run.sh. Check Quickshell version and startup errors; if a module/API is missing, record the exact error before changing versions.
- [ ] Verify legacy pins and preferences migrated, and git status stays clean after changing settings/pins.
- [ ] Save settings, relaunch, verify persistence; try malformed JSON using a backup; restore valid JSON and verify live reload.
- [ ] Verify both Darkman mode transitions, glass blur, opaque icons, hover labels and Walker launch.
- [ ] Try pin drag/drop, canceled drag, reordering after relaunch, and context-menu settings.
- [ ] Launch a pinned app; verify pending state clears on appearance and no-window timeout.
- [ ] Verify native Wayland, XWayland, Flatpak/PWA and custom entries; excluded helper stays functional but hidden.
- [ ] Verify focus across workspaces, grouped picker, and menu position on both monitors.
- [ ] Verify edge trigger at both corners and center, transit to dock, hide delay, menu hold, fullscreen and no tile resize.
- [ ] Hotplug monitor, mixed scales, disconnect while popup open, and optional monitor exclusions.
- [ ] Trigger actual compositor urgency, focus to clear, test notification-only and fullscreen cases.
- [ ] Test native minimize with disposable window; if ignored, revert to off. Optionally test workspace mode and recovery after restart. Restore every minimized window before rollback.
- [ ] Stop manual instance, enable UWSM service, confirm one running process and journal output.
- [ ] Logout/login and reboot; verify one instance, no KDE autostart, correct theme and pins. Disable service and verify manual startup still works.

Record versions, commit SHA, observed results and logs before updating the host deployment record.

## Stabilization retest

- [ ] Launcher ring is absent and there are no undefined boolean warnings.
- [ ] Running apps show neutral indicators; focused app has stronger blue indicator. Closed pins have none.
- [ ] Change icon size 36 → 48 → 36 through slider and spin box; check immediate dock geometry and persistence.
- [ ] Enable magnification at 150%; hover across each slot and move out without flicker or incorrect activation.
- [ ] Test Cancel and Save from every tab, theme-specific opacity and radius, identity validation, and reset preview.
- [ ] Open two Firefox windows; hover/click the one icon and select each listed window.
- [ ] Workspace mode: repeatedly minimize and restore a disposable window in the focused numeric workspace; click a window on another workspace to focus, then click again to minimize. Check logs for confirmed moves.
- [ ] Confirm only one service process and reboot/login behavior. Hotplug remains outstanding until a second screen is available.

## Follow-up: hover and save recovery

Owner confirmed launcher, indicators, icon sizing, workspace actions, grouped windows, persistence, Cancel and pin reordering at ad89110. Magnification and intermittent save completion remained defective. Retest with auto-hide both on and off: sweep across icons at 150%, stop on an icon, leave the dock, open/close a grouped picker and drag a pin. All icons must return to normal size after leaving, hiding or opening a popup. Save repeatedly including no edits, confirm the status returns to idle, then verify restart persistence. If a save completion is lost, disk read-back should confirm it or the panel should report an error and allow reload/cancel within the bounded timeout. Fresh login and multi-monitor acceptance remain outstanding.
