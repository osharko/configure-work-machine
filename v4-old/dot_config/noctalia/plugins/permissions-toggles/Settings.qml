import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    spacing: 12

    NText {
        text: "Plugin Settings"
        font.pixelSize: 16
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        NText { text: "Script path"; Layout.preferredWidth: 140 }
        TextField {
            Layout.fillWidth: true
            text: pluginApi?.pluginSettings?.scriptPath ?? "~/.local/bin/system-toggle"
            onTextChanged: if (pluginApi?.pluginSettings) pluginApi.pluginSettings.scriptPath = text
        }
    }

    RowLayout {
        Layout.fillWidth: true
        NText { text: "Refresh interval (sec)"; Layout.preferredWidth: 140 }
        SpinBox {
            from: 1; to: 60
            value: pluginApi?.pluginSettings?.refreshIntervalSec ?? 5
            onValueChanged: if (pluginApi?.pluginSettings) pluginApi.pluginSettings.refreshIntervalSec = value
        }
    }
}
