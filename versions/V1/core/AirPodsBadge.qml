import QtQuick

Item {
    id: badge
    required property var theme
    property color foreground: theme.ink
    implicitWidth: 26
    implicitHeight: 28
    z: 2
    AirPodsService { id: pods }
    AirPodsIcon {
        anchors.centerIn: parent
        iconSize: 18
        variant: pods.isHeadset ? "max" : pods.isProSeries ? "pro" : "buds"
        color: pods.hasAirPods ? badge.theme.seal : Qt.rgba(badge.foreground.r, badge.foreground.g, badge.foreground.b, 0.5)
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) pods.cycleNoiseMode()
            else {
                badge.theme.activateFocusedPopupScreen()
                badge.theme.airpodsBarX = badge.mapToItem(null, badge.width / 2, 0).x
                badge.theme.airpodsVisible = !badge.theme.airpodsVisible
            }
        }
    }
}
