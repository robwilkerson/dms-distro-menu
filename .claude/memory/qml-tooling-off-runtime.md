---
name: qml-tooling-off-runtime
description: How qmllint and qmlformat behave against this plugin outside the DMS runtime, and why qmlformat must never be enforced
metadata:
  type: project
---

The Qt QML tools work on this repo only with caveats, because every `qs.*`
module, `Quickshell`, and the `Theme` / `SessionService` globals exist solely
inside the DMS runtime.

**`qmllint`** floods with noise unless three categories are disabled:

```sh
qmllint --import disable --unqualified disable --unresolved-type disable \
  DistroMenu.qml DistroMenuSettings.qml
```

- `import` — "Failed to import qs.Common" and friends
- `unqualified` — `Theme`, `SessionService`, `Quickshell` are runtime globals
- `unresolved-type` — `anchors` / `font` on a DMS base type that did not resolve

With those off it exits 0 on a clean tree and 255 on a syntax error. No import
path flag is needed; even `QtQuick` fails to resolve and that is fine.

**`qmlformat` must not be enforced.** It reflows expressions onto single
physical lines, which flattens the deliberately wrapped `extraScript` shell
string (~900 chars) and the `refreshAbout()` ternaries. The semantics are
identical and the code is much worse.

**Why:** this was measured on 2026-08-28 while scoping a GitHub Actions lint
workflow. The workflow was then dropped: what remains after the three disables
is syntax checking on two files, which did not justify the CI.

**How to apply:** if lint comes up again, reach for `just doctor` first — it
checks the invariants that actually fail silently. Never add a `qmlformat`
gate, and never run `qmlformat -i` over `DistroMenu.qml`.
