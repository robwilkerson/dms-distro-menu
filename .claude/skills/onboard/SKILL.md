---
name: onboard
description: Onboard a new contributor (or a fresh machine) to the Distro Menu DMS plugin. Use after cloning the repo.
---

# Onboard

Get set up to work on Distro Menu — a DankMaterialShell (DMS) dankbar plugin.

## Orientation

Read these first:

- **`README.md`** — what the widget is, the bar/dropdown/settings behavior, and
  how it installs into DMS.
- **`DistroMenu.qml`** — the whole widget in one file: bar pill, dropdown, and
  the on-demand About-fact refresh. The header comment maps the menu layout.
- Skim the **DankMaterialShell** plugin docs/source
  (github.com/AvengeMedia/DankMaterialShell) for the `qs.*` imports, `Theme`
  tokens, and the plugin settings API this widget builds on.

## Prerequisites

- **DankMaterialShell + `dms`** (v1.4.0+) — provides the Quickshell runtime, the
  `qs.*` modules, `SessionService`, and the `dms ipc` surface.
- **`dgop`** — supplies the About-panel hardware facts (ships with DMS).
- **`qmllint` / `qmlformat`** (optional) — Qt QML lint/format tooling, from your
  distro's Qt6 declarative-tools package.

If any prerequisite is unclear for your setup, ask — the definitive list can
depend on how DMS was installed on your machine.

## Install

DMS loads plugins from `~/.config/DankMaterialShell/plugins/`, not from the repo.
Clone anywhere, then:

```sh
just bootstrap       # check tooling, report which copy the bar is running
just develop start   # symlink this tree in, moving any installed copy aside
just restart         # a develop swap changes the source path; reload is not enough
```

Then enable it via Settings → Plugin Management.

If your package manager installs the plugin (a nix profile, say), `just status`
will show a real directory rather than a symlink. Edits in this tree do not
reach the bar until you rebuild, and neither a reload nor a restart will say so.

## Integrations

No integrations require user-specific setup for this project. Everything runs
against local shell commands and the `dms` IPC socket.
