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
