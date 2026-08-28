# Distro Menu

A DankMaterialShell (DMS) "dankbar" plugin widget. It puts the distro logo
far-left on the bar and opens a macOS Apple-menu-style dropdown: an "About this
system" card, Settings, Lock, and power actions. Single QML plugin, no backend.

## Stack & runtime

- **QML / QtQuick** loaded directly by DMS's Quickshell runtime. There is **no
  build step** and **no compile** — DMS reads the `.qml` files at load time.
- Imports `qs.Common`, `qs.Services`, `qs.Widgets`, `qs.Modules.Plugins`, and
  `Quickshell`. These resolve **only inside the DMS runtime** — they are not
  local modules and won't resolve in a plain editor/linter. Don't add a local
  stub or module path for them.
- Requires DMS `>=1.4.0` (local is v1.5.0) and the `dgop` binary (ships with
  DMS) for About facts.

## Files

- `plugin.json` — manifest: `id` is `distroMenu`, declares the component,
  settings panel, `permissions`, and `requires_dms`. Bump `version` on release.
- `DistroMenu.qml` — the widget: bar pill + dropdown, About-fact refresh logic.
- `DistroMenuSettings.qml` — the Settings → Plugin Management panel.

## Conventions (beyond global defaults)

- Use DMS-provided widgets and tokens; don't hand-roll styling. `StyledText`,
  `DankIcon`, `SystemLogo`, `PopoutComponent`, `PluginComponent`, and all
  `Theme.*` tokens (colors, `spacing*`, `fontSize*`, `cornerRadius`) come from
  DMS. Match existing usage.
- Comment style: descriptive prose blocks; section dividers use box-drawing
  rules (`// ── Section ──`). Match it.
- About facts are read **on demand** each time the dropdown opens
  (`Proc.runCommand` → `dgop hardware --json`, `uptime -p`, and one batched
  `extraScript`). Keep reads **fail-soft**: a missing tool must never abort the
  rest, and stale values beat a broken card.
- Power actions (`SessionService.logout/reboot/poweroff/suspend`) **fire
  directly, no confirmation** — intentional. Don't add a confirm prompt without
  being asked.

## Adding an "About" field

Three coordinated edits: (1) a `ToggleSetting` in `DistroMenuSettings.qml`;
(2) an `aboutX` property + its parse in `refreshAbout()` in `DistroMenu.qml`;
(3) a `factRows` entry. `settingKey` in settings must match the `key` in
`factRows`; `pref(key, def)` reads it back. Settings persist via DMS's plugin
settings API keyed `"distroMenu"` and are read reactively through `pluginData`.

## Run / verify

No test suite. `just` drives the local loop: `just status` reports which copy
the bar is actually running, `just doctor` checks the invariants that fail
silently, `just reload` / `just restart` re-read the QML and the manifest.

DMS loads from `~/.config/DankMaterialShell/plugins/distroMenu`, which is not
necessarily this repo: it may be a symlink to your tree, or a real directory
your package manager populates, in which case edits here reach the bar only on
the next rebuild. `just status` reports which. `just develop start` symlinks
this tree over the installed copy, `just develop stop` restores it. Lint with
`qmllint` / `qmlformat` if installed.

## Tracking & CI

- **Issues:** GitHub Issues on `robwilkerson/dms-distro-menu`.
- **CI:** *Intended, not yet committed* — GitHub Actions QML lint via
  `qmllint` / `qmlformat`. No `.github/workflows/` exists yet.

## Related Projects

Read on-demand; never preload at session start.

- **Reference** DankMaterialShell (github.com/AvengeMedia/DankMaterialShell) —
  the upstream shell this plugin targets. Source of every `qs.*` import,
  `Theme` token, `SessionService`, `SystemLogo`, the plugin settings API, and
  the `dms ipc` surface. Consult its source/docs when touching plugin-API
  integration. This repo consumes DMS; no coordination flows back.
