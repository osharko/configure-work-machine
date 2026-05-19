import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    readonly property var main: pluginApi?.mainInstance ?? null

    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 380 * Style.uiScaleRatio
    // Altezza dinamica: somma di header + 2 container + spacing
    property real contentPreferredHeight: mainColumn.implicitHeight + Style.marginM * 2
    readonly property bool allowAttach: true

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            // ── Header ──
            NBox {
                Layout.fillWidth: true
                Layout.preferredHeight: headerRow.implicitHeight + Style.marginM * 2

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    NIcon {
                        icon: "shield-check"
                        color: Color.mPrimary
                        pointSize: Style.fontSizeL
                    }
                    NText {
                        Layout.fillWidth: true
                        text: "Permissions Toggles"
                        font.weight: Style.fontWeightBold
                        pointSize: Style.fontSizeL
                        color: Color.mOnSurface
                    }
                }
            }

            // ── Container 1: Login ──
            NBox {
                Layout.fillWidth: true
                Layout.preferredHeight: loginCol.implicitHeight + Style.marginM * 2

                ColumnLayout {
                    id: loginCol
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    NToggle {
                        label: "Autologin tty1"
                        description: "Salta SDDM, login automatico al boot (richiede LUKS)"
                        checked: main?.autologinTtyStatus === "on"
                        onToggled: c => main?.applyToggle("autologin-tty", c)
                    }
                    NToggle {
                        label: "Noctalia lock al boot"
                        description: "Mostra lock screen Noctalia al boot invece di SDDM (workaround)"
                        checked: main?.noctaliaLockOnBootStatus === "on"
                        onToggled: c => main?.applyToggle("noctalia-lock-on-boot", c)
                    }
                }
            }

            // ── Container 2: Auth ──
            NBox {
                Layout.fillWidth: true
                Layout.preferredHeight: authCol.implicitHeight + Style.marginM * 2

                ColumnLayout {
                    id: authCol
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginS

                    NToggle {
                        label: "Sudo no password"
                        description: "Disabilita prompt password per ogni sudo"
                        checked: main?.passwordlessSudoStatus === "on"
                        onToggled: c => main?.applyToggle("passwordless-sudo", c)
                    }
                    NToggle {
                        label: "Keyring no password"
                        description: "Sblocco automatico keyring GNOME al login"
                        checked: main?.keyringNoPasswordStatus === "on"
                        onToggled: c => main?.applyToggle("keyring-no-password", c)
                    }
                    NToggle {
                        label: "No-sudo abbreviations"
                        description: "Auto-prefix sudo a pacman/systemctl/mount/…"
                        checked: main?.sudolessAbbreviationsStatus === "on"
                        onToggled: c => main?.applyToggle("sudoless-abbreviations", c)
                    }
                    NToggle {
                        label: "Disable faillock"
                        description: "Nessun blocco account dopo tentativi password falliti"
                        checked: main?.disableFaillockStatus === "on"
                        onToggled: c => main?.applyToggle("disable-faillock", c)
                    }
                    NToggle {
                        label: "Polkit no password (wheel)"
                        description: "Skip prompt polkit per utenti in wheel (anche pkexec)"
                        checked: main?.polkitNoPasswordStatus === "on"
                        onToggled: c => main?.applyToggle("polkit-no-password", c)
                    }
                }
            }
        }
    }

    onVisibleChanged: if (visible && main) main.refreshAll()
}
