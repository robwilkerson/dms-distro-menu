// Distro Menu — DankMaterialShell dankbar widget.
//
// Bar: the distro logo (auto-detected from /etc/os-release via the shared
// SystemLogo widget — nerd-font glyph for Fedora/Arch/etc.). Sits far-left,
// where the macOS Apple menu lives. Clicking it opens a grouped dropdown
// modeled on the Apple menu:
//
//   About this system   (configurable fields — see DistroMenuSettings.qml)
//   ───
//   Settings            → DMS settings   (dms ipc call settings open)
//   ───
//   Lock                → DMS lock       (dms ipc call lock lock)
//   ───
//   Log Out / Restart / Shut Down / Sleep  → SessionService (fire directly)
//
// About facts are read on demand (dgop + a few cheap shell reads) when the
// dropdown opens, so the plugin stays self-contained — no DgopService ref
// lifecycle to manage. Which facts appear is driven by per-field toggles
// persisted through DMS's plugin settings (reactive `pluginData`).

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // ── About this system (refreshed when the dropdown opens) ───────────
    property string aboutDistro: ""
    property string aboutKernel: ""
    property string aboutHost: ""
    property string aboutUptime: ""
    property string aboutArch: ""
    property string aboutCpu: ""
    property string aboutMemory: ""
    property string aboutDisk: ""
    property string aboutBattery: ""
    property string aboutIp: ""
    property string aboutShell: ""
    property string aboutWm: ""

    // Per-field visibility, read from plugin settings with a default. Distro
    // (the card heading), kernel, host, and uptime default on; the rest are
    // opt-in via Settings → Plugin Management → Distro Menu.
    function pref(key, def) {
        return pluginData[key] !== undefined ? pluginData[key] : def;
    }

    // One batched read for the fields dgop/uptime don't cover. Guarded so a
    // single missing tool never aborts the rest.
    readonly property string extraScript:
        "free -h 2>/dev/null | awk '/^Mem:/{print \"mem=\"$3\" / \"$2}';" +
        "df -h --output=used,size / 2>/dev/null | tail -1 | awk '{print \"disk=\"$1\" / \"$2}';" +
        "ip=$(hostname -I 2>/dev/null | awk '{print $1}'); [ -n \"$ip\" ] && echo \"ip=$ip\";" +
        "sh=$(basename \"$(getent passwd \"$(id -u)\" | cut -d: -f7)\" 2>/dev/null); [ -n \"$sh\" ] && echo \"shell=$sh\";" +
        "wm=$(niri --version 2>/dev/null | head -1); [ -n \"$wm\" ] && echo \"wm=$wm\";" +
        "for b in /sys/class/power_supply/*; do [ \"$(cat \"$b/type\" 2>/dev/null)\" = Battery ] || continue;" +
        "cap=$(cat \"$b/capacity\" 2>/dev/null); st=$(cat \"$b/status\" 2>/dev/null);" +
        "[ -n \"$cap\" ] && echo \"battery=$cap% ($st)\"; break; done"

    function refreshAbout() {
        // dgop hardware --json → { distro, kernel, hostname, arch, cpu, ... }
        Proc.runCommand("distroMenu-hw", ["sh", "-c", "dgop hardware --json"], function (output, exitCode) {
            if (exitCode !== 0 || !output)
                return;
            try {
                const d = JSON.parse(output.trim());
                root.aboutDistro = d.distro || "";
                root.aboutKernel = d.kernel || "";
                root.aboutHost = d.hostname || "";
                root.aboutArch = d.arch || "";
                if (d.cpu)
                    root.aboutCpu = (d.cpu.model && d.cpu.model.length > 0)
                        ? d.cpu.model
                        : (d.cpu.count ? d.cpu.count + " cores" : "");
            } catch (e) {
                // Leave prior values; a stale reading beats a broken card.
            }
        });
        Proc.runCommand("distroMenu-uptime", ["sh", "-c", "uptime -p"], function (output, exitCode) {
            if (exitCode === 0 && output)
                root.aboutUptime = output.trim();
        });
        Proc.runCommand("distroMenu-extra", ["sh", "-c", root.extraScript], function (output, exitCode) {
            if (exitCode !== 0 || !output)
                return;
            const lines = output.trim().split("\n");
            for (var i = 0; i < lines.length; i++) {
                const eq = lines[i].indexOf("=");
                if (eq < 0)
                    continue;
                const k = lines[i].substring(0, eq);
                const v = lines[i].substring(eq + 1);
                if (k === "mem") root.aboutMemory = v;
                else if (k === "disk") root.aboutDisk = v;
                else if (k === "ip") root.aboutIp = v;
                else if (k === "shell") root.aboutShell = v;
                else if (k === "wm") root.aboutWm = v;
                else if (k === "battery") root.aboutBattery = v;
            }
        });
    }

    // Ordered fact rows (distro is the card heading, handled separately). Each
    // row shows only when its toggle is on AND the value resolved non-empty.
    readonly property var factRows: [
        { "key": "showKernel",  "def": true,  "label": "Kernel",   "value": root.aboutKernel },
        { "key": "showHost",    "def": true,  "label": "Host",     "value": root.aboutHost },
        { "key": "showUptime",  "def": true,  "label": "Uptime",   "value": root.aboutUptime },
        { "key": "showArch",    "def": false, "label": "Arch",     "value": root.aboutArch },
        { "key": "showCpu",     "def": false, "label": "CPU",      "value": root.aboutCpu },
        { "key": "showMemory",  "def": false, "label": "Memory",   "value": root.aboutMemory },
        { "key": "showDisk",    "def": false, "label": "Disk",     "value": root.aboutDisk },
        { "key": "showBattery", "def": false, "label": "Battery",  "value": root.aboutBattery },
        { "key": "showIp",      "def": false, "label": "Local IP", "value": root.aboutIp },
        { "key": "showShell",   "def": false, "label": "Shell",    "value": root.aboutShell },
        { "key": "showWm",      "def": false, "label": "WM",       "value": root.aboutWm }
    ]

    // Prime the fields so the first open paints populated.
    Component.onCompleted: root.refreshAbout()

    readonly property real iconSize: Math.max(16, Math.round(root.barThickness * 0.5))

    // ── Bar pill: distro logo ───────────────────────────────────────────
    // SystemLogo is visual-only (no MouseArea), so clicks fall through to
    // BasePill's z:-1 MouseArea and toggle the dropdown.
    horizontalBarPill: Component {
        Item {
            implicitWidth: root.iconSize
            implicitHeight: root.iconSize

            SystemLogo {
                anchors.centerIn: parent
                width: root.iconSize
                height: root.iconSize
            }
        }
    }

    // ── Dropdown ────────────────────────────────────────────────────────
    popoutWidth: 300
    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "System"
            showCloseButton: true

            Component.onCompleted: root.refreshAbout()

            // Shared action-row: icon + label, hover highlight, click handler.
            // `action` is a 0-arg function invoked on click; the popout closes
            // afterward so the menu behaves like a real menu.
            Component {
                id: actionRowComp

                Rectangle {
                    id: actionRow
                    required property var modelData  // { icon, label, action }

                    width: parent ? parent.width : 0
                    height: Theme.iconSize + Theme.spacingS
                    radius: Theme.cornerRadius
                    color: actionMouse.containsMouse
                        ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
                        : "transparent"

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (actionRow.modelData.action)
                                actionRow.modelData.action();
                            if (popout.closePopout)
                                popout.closePopout();
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingM

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: actionRow.modelData.icon
                            size: Theme.fontSizeLarge
                            color: Theme.surfaceText
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: actionRow.modelData.label
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                // ── About this system ──────────────────────────────────
                Rectangle {
                    width: parent.width
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    height: aboutCol.implicitHeight + Theme.spacingM * 2

                    Column {
                        id: aboutCol
                        x: Theme.spacingM
                        y: Theme.spacingM
                        width: parent.width - Theme.spacingM * 2
                        spacing: Theme.spacingXS

                        // Heading: the distro name when enabled, else generic.
                        StyledText {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: (root.pref("showDistro", true) && root.aboutDistro.length > 0)
                                ? root.aboutDistro
                                : "About this system"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.DemiBold
                            color: Theme.surfaceText
                        }

                        // key/value facts, hidden unless toggled on and populated.
                        Repeater {
                            model: root.factRows

                            delegate: Item {
                                id: fact
                                required property var modelData
                                width: aboutCol.width
                                height: visible ? factRow.implicitHeight : 0
                                visible: root.pref(fact.modelData.key, fact.modelData.def)
                                    && fact.modelData.value.length > 0

                                Row {
                                    id: factRow
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    StyledText {
                                        width: 62
                                        text: fact.modelData.label
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.outline
                                    }

                                    StyledText {
                                        width: parent.width - 62 - Theme.spacingS
                                        elide: Text.ElideRight
                                        text: fact.modelData.value
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                    }
                                }
                            }
                        }
                    }
                }

                // Divider between clusters. Direct Column children (not
                // Loader-wrapped) so their fixed height lays out correctly.
                Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.15 }

                // ── Settings ────────────────────────────────────────────
                Repeater {
                    model: [{
                        "icon": "settings",
                        "label": "Settings",
                        "action": function () { Quickshell.execDetached(["dms", "ipc", "call", "settings", "open"]); }
                    }]
                    delegate: actionRowComp
                }

                Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.15 }

                // ── Lock ────────────────────────────────────────────────
                Repeater {
                    model: [{
                        "icon": "lock",
                        "label": "Lock",
                        "action": function () { Quickshell.execDetached(["dms", "ipc", "call", "lock", "lock"]); }
                    }]
                    delegate: actionRowComp
                }

                Rectangle { width: parent.width; height: 1; color: Theme.outline; opacity: 0.15 }

                // ── Power cluster (fires directly, no confirm) ──────────
                Repeater {
                    model: [
                        { "icon": "logout", "label": "Log Out", "action": function () { SessionService.logout(); } },
                        { "icon": "restart_alt", "label": "Restart", "action": function () { SessionService.reboot(); } },
                        { "icon": "power_settings_new", "label": "Shut Down", "action": function () { SessionService.poweroff(); } },
                        { "icon": "bedtime", "label": "Sleep", "action": function () { SessionService.suspend(); } }
                    ]
                    delegate: actionRowComp
                }
            }
        }
    }
}
