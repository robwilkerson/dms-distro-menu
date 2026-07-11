// Distro Menu — settings panel (Settings → Plugin Management → Distro Menu).
//
// One toggle per "About this system" field. Values persist through DMS's
// plugin settings API (plugin_settings.json, keyed "distroMenu") and are read
// back reactively by DistroMenu.qml via `pluginData`.

import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "distroMenu"

    StyledText {
        width: parent.width
        text: "Show in About"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    // Defaults-on: the original four fields.
    ToggleSetting {
        settingKey: "showDistro"
        label: "Distro name"
        description: "Distro + version as the card heading (else a generic title)"
        defaultValue: true
    }
    ToggleSetting {
        settingKey: "showKernel"
        label: "Kernel"
        description: "Running kernel version"
        defaultValue: true
    }
    ToggleSetting {
        settingKey: "showHost"
        label: "Host"
        description: "Hostname"
        defaultValue: true
    }
    ToggleSetting {
        settingKey: "showUptime"
        label: "Uptime"
        description: "Time since boot"
        defaultValue: true
    }

    // Opt-in extras.
    ToggleSetting {
        settingKey: "showArch"
        label: "Architecture"
        description: "CPU architecture (e.g. aarch64)"
        defaultValue: false
    }
    ToggleSetting {
        settingKey: "showCpu"
        label: "CPU"
        description: "Processor model, or core count if the model is unknown"
        defaultValue: false
    }
    ToggleSetting {
        settingKey: "showMemory"
        label: "Memory"
        description: "Used / total RAM"
        defaultValue: false
    }
    ToggleSetting {
        settingKey: "showDisk"
        label: "Disk"
        description: "Used / total on the root filesystem"
        defaultValue: false
    }
    ToggleSetting {
        settingKey: "showBattery"
        label: "Battery"
        description: "Charge percentage and status"
        defaultValue: false
    }
    ToggleSetting {
        settingKey: "showIp"
        label: "Local IP"
        description: "Primary local IPv4 address"
        defaultValue: false
    }
    ToggleSetting {
        settingKey: "showShell"
        label: "Shell"
        description: "Login shell"
        defaultValue: false
    }
    ToggleSetting {
        settingKey: "showWm"
        label: "Window manager"
        description: "Compositor and version (niri)"
        defaultValue: false
    }
}
