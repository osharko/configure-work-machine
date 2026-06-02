import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pluginApi: null

    function scriptPath() {
        const raw = pluginApi?.pluginSettings?.scriptPath ?? "~/.local/bin/system-toggle";
        return raw.replace(/^~/, Quickshell.env("HOME") ?? "");
    }

    function refreshIntervalSec() {
        return pluginApi?.pluginSettings?.refreshIntervalSec ?? 5;
    }

    // Stato dei toggle (refreshato periodicamente)
    property string passwordlessSudoStatus: "?"
    property string sudolessAbbreviationsStatus: "?"
    property string autologinTtyStatus: "?"
    property string keyringNoPasswordStatus: "?"
    property string noctaliaLockOnBootStatus: "?"
    property string disableFaillockStatus: "?"
    property string polkitNoPasswordStatus: "?"

    // Lancia "system-toggle status <name>" e aggiorna il rispettivo property
    function refreshStatus(name, propertyName) {
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process { stdout: SplitParser {} }',
            root
        );
        proc.command = ["bash", "-lc", scriptPath() + " status " + name];
        proc.stdout.read.connect(line => {
            root[propertyName] = line.trim();
        });
        proc.running = true;
    }

    function refreshAll() {
        if (!pluginApi) return;
        refreshStatus("passwordless-sudo",      "passwordlessSudoStatus");
        refreshStatus("sudoless-abbreviations", "sudolessAbbreviationsStatus");
        refreshStatus("autologin-tty",          "autologinTtyStatus");
        refreshStatus("keyring-no-password",    "keyringNoPasswordStatus");
        refreshStatus("noctalia-lock-on-boot",  "noctaliaLockOnBootStatus");
        refreshStatus("disable-faillock",       "disableFaillockStatus");
        refreshStatus("polkit-no-password",     "polkitNoPasswordStatus");
    }

    // Lancia "system-toggle on|off <name>" + refresh
    function applyToggle(name, on) {
        const action = on ? "on" : "off";
        const proc = Qt.createQmlObject(
            'import Quickshell.Io; Process {}',
            root
        );
        proc.command = ["bash", "-lc", scriptPath() + " " + action + " " + name];
        proc.running = true;
        proc.exited.connect(() => {
            // refresh immediato (caso file ops user, no pkexec)
            refreshAll();
            // + refresh delayed 400ms (caso pkexec che ritarda il fs commit)
            postToggleTimer.restart();
        });
    }

    // Timer di refresh periodico
    property Timer refreshTimer: Timer {
        interval: refreshIntervalSec() * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }

    // Timer di refresh post-toggle (dopo pkexec, attendi che il filesystem sia
    // aggiornato prima di rileggere lo stato)
    property Timer postToggleTimer: Timer {
        interval: 400
        running: false
        repeat: false
        onTriggered: root.refreshAll()
    }

    Component.onCompleted: {
        if (pluginApi) pluginApi.mainInstance = root
        refreshAll()
    }
    onPluginApiChanged: {
        if (pluginApi) pluginApi.mainInstance = root
        refreshAll()
    }
}
