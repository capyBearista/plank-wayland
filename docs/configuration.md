# Configuration reference

Edit settings.json under the XDG config directory, or open the dock settings panel. The format is an object with schemaVersion: 1, dock, styleName, uiLanguage, indicatorStyle and optional styleOverrides. Defaults live in settings.js; keys in dock are merged against defaults and bounded where appropriate. Malformed JSON retains last valid runtime settings; the panel reports conflicts and save errors. Save UI edits explicitly. Closing the panel retains unsaved live edits; Reload / discard unsaved edits re-reads the file.

| dock key | Default | Purpose |
| --- | --- | --- |
| iconSize | 36 | Icon size (32–96) |
| zoomEnabled | false | Magnification |
| zoomPercent | 100 | Magnification amount |
| followSystemIconTheme | true | Use detected GTK/KDE icon theme |
| itemPadding | 2.5 | Spacing |
| horizPadding | 0 | Horizontal padding |
| autoHide | true | Hide when not engaged |
| smartHide | false | Hide when windows overlap |
| bottomGap | 12 | Bottom gap, 0–80 logical px |
| edgeTriggerHeight | 3 | Activation strip, 1–20 logical px |
| hideDelayMs | 300 | Hide delay, 0–5000 ms |
| hoverMenuDelayMs | 400 | Group hover picker delay |
| themeMode | system | system/light/dark/manual |
| lightStyle | clear-glass-light | Light preset |
| darkStyle | clear-glass | Dark preset |
| launcherIcon | "" | Icon name or absolute path; built-in grid fallback |
| launcherCommand | [] | Empty selects walker-themed; otherwise argument array |
| excludedApps | ["xwaylandvideobridge"] | Exact normalized IDs |
| identityOverrides | {} | Raw app ID to desktop entry ID |
| excludedMonitors | [] | Exact connector names |
| minimizeMode | off | off/native/workspace (experimental) |
| attentionReveal | true | Reveal for new compositor urgency |
| attentionRevealMs | 5000 | Reveal timeout |
| attentionInFullscreen | false | Allow auto-reveal over fullscreen |
| launchFeedback | true | Pending state for app launches |
| launchTimeoutMs | 10000 | Bounded launch timeout |
| dragReorder | true | Reorder pinned items |

Other legacy style and timing fields are retained in settings.js. styleName chooses the manual preset. indicatorStyle is line/dot/legacy. styleOverrides preserves per-preset customizations. Use JSON arrays for commands to avoid shell quoting and injection; old explicit pinned command strings are treated as trusted local configuration. Do not copy untrusted command strings into your config.

Examples (merge with existing dock object; do not replace the entire file):

```json
{
  "launcherIcon": "start-here",
  "excludedApps": ["xwaylandvideobridge", "org.example.Helper"],
  "identityOverrides": {"example": "org.example.App"},
  "excludedMonitors": ["HDMI-A-1"],
  "hideDelayMs": 500
}
```

Pins are an ordered JSON array of objects with appId, optional canonicalId, desktopId, name, icon, iconAliases, fallback and command. Do not edit the file concurrently with pin operations. Exclusions hide pins without deleting them.

Known limits: per-monitor filtering of application lists is not enabled; all monitors share the same app list. Pin reordering is pinned-only. Notification-only events are not treated as compositor urgency. Direct refraction, window thumbnails and other unselected backlog features are outside this implementation.
