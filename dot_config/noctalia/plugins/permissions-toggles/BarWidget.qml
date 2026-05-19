import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    baseSize: Style.getCapsuleHeightForScreen(screen?.name)
    applyUiScale: false
    icon: "shield-check"
    tooltipText: "Permissions Toggles"
    tooltipDirection: BarService.getTooltipDirection(screen?.name)
    customRadius: Style.radiusL

    colorBg: Style.capsuleColor
    colorFg: Color.mOnSurface
    colorBgHover: Color.mHover
    colorFgHover: Color.mOnHover
    colorBorder: "transparent"
    colorBorderHover: "transparent"

    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    onClicked: {
        if (pluginApi?.openPanel) pluginApi.openPanel(screen, this);
    }
}
