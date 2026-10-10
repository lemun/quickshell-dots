import QtQuick

Item {
    id: badge
    required property var theme
    required property var screen
    property color activeForeground: theme.seal
    property color foreground: theme.ink
    implicitWidth: 26
    implicitHeight: 28
    z: 2
    AirPodsService { id: pods }
    AirPodsIcon {
        anchors.centerIn: parent
        iconSize: 18
        variant: pods.isHeadset ? "max" : pods.isProSeries ? "pro" : "buds"
        color: pods.hasAirPods ? badge.activeForeground : Qt.rgba(badge.foreground.r, badge.foreground.g, badge.foreground.b, 0.5)
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) pods.cycleNoiseMode()
            else {
                badge.theme.activatePopupScreen(badge.screen)
                badge.theme.setPanelAnchor("airpods", badge.mapToItem(null, badge.width / 2, 0).x, badge.screen.name)
                badge.theme.airpodsVisible = !badge.theme.airpodsVisible
            }
        }
    }
}
