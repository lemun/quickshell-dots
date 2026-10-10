import QtQuick
import Quickshell
import Quickshell.Wayland
import "../variants/V2/modules" as V2
import "Model.js" as Model

PanelWindow {
    id: panel
    required property var root
    screen: root.activePopupScreen
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "custom-airpods"
    readonly property bool isV2: root.v2BarHeight !== undefined
    readonly property int barBottom: isV2 ? root.v2BarHeight : 35
    property real reveal: root.airpodsVisible ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: panel.root.airpodsVisible ? 160 : 120
            easing.type: panel.root.airpodsVisible ? Easing.OutCubic : Easing.InCubic
        }
    }
    visible: reveal > 0.001
    WlrLayershell.keyboardFocus: root.airpodsVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    AirPodsService { id: pods }
    MouseArea { anchors.fill: parent; onClicked: root.airpodsVisible = false }
    component MenuText: Text {
        color: root.ink
        font.family: root.mono
        font.pixelSize: 11
        renderType: Text.NativeRendering
    }
    component MenuButton: Rectangle {
        id: button
        property string text: ""
        property bool selected: false
        property color labelColor: selected ? root.seal : root.ink
        signal clicked()
        width: contents.width
        height: 28
        radius: (panel.isV2 ? root.panelButtonRadius : 6)
        color: selected ? root.fillActive
            : action.containsMouse ? root.fillHover : root.fillIdle
        border.color: selected || action.containsMouse ? root.seal : root.sep
        border.width: 1
        Behavior on color { ColorAnimation { duration: 120 } }
        MenuText {
            anchors.centerIn: parent
            text: button.text
            color: button.labelColor
        }
        MouseArea {
            id: action
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
        Rectangle {
            id: card
            width: 300
            height: contents.implicitHeight + 24
            x: Math.round(Math.max(6, Math.min(root.airpodsBarX - width / 2, parent.width - width - 6)))
            y: root.barPosition === "bottom"
                ? parent.height - barBottom - 6 - height + 2 * (1 - panel.reveal)
                : barBottom + 6 - 2 * (1 - panel.reveal)
            opacity: panel.reveal
            focus: root.airpodsVisible
            Keys.onEscapePressed: root.airpodsVisible = false
            MouseArea { anchors.fill: parent; onClicked: {} }
            Loader {
                anchors.fill: parent
                active: panel.isV2
                onLoaded: item.parent = card
                sourceComponent: Component {
                    V2.ConnectedPanelSurface {
                        root: panel.root
                        ownerActive: panel.root.airpodsVisible
                        targetX: panel.root.airpodsBarX
                        reveal: panel.reveal
                    }
                }
            }
            radius: panel.isV2 ? root.panelRadius : root.pillRadius
            color: panel.isV2 ? "transparent" : root.bg
            border.color: panel.isV2 ? root.panelBorder : root.pillBorder
            border.width: panel.isV2 ? 0 : root.pillBorderW
            Column {
                id: contents
                // The loaded V2 surface is reparented after this column.
                z: 1
                x: 12; y: 12
                width: parent.width - 24
                spacing: 8
                Item {
                    width: parent.width; height: 24
                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        MenuText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "AirPods"
                            font.pixelSize: 13
                            font.letterSpacing: 2
                            font.weight: Font.Medium
                        }
                        AirPodsIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            iconSize: 16
                            variant: pods.isHeadset ? "max" : pods.isProSeries ? "pro" : "buds"
                            color: root.seal
                        }
                    }
                    MenuText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        color: closeMouse.containsMouse ? root.seal : root.sumi
                        font.pixelSize: 12
                        Behavior on color { ColorAnimation { duration: 120 } }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            anchors.margins: -5
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.airpodsVisible = false
                        }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: root.sep }
                MenuText {
                    visible: pods.hasAirPods || pods.hasBattery
                    width: parent.width
                    text: pods.deviceName || pods.modelName || "AirPods"
                    elide: Text.ElideRight
                    font.weight: Font.Medium
                }
                MenuText {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: pods.lastError ? pods.lastError
                        : !pods.daemonReachable ? "AirPods service unavailable"
                        : !pods.hasAirPods && !pods.hasBattery ? "AirPods disconnected"
                        : pods.isHeadset ? "Battery: " + Model.levelText(pods.headsetBattery.level) + (pods.headsetBattery.charging ? " · Charging" : "")
                        : "Left: " + Model.levelText(pods.leftPod.level) + (pods.leftPod.charging ? " ⚡" : "")
                            + "   Right: " + Model.levelText(pods.rightPod.level) + (pods.rightPod.charging ? " ⚡" : "")
                            + "\nCase: " + Model.levelText(pods.caseBattery.level) + (pods.caseBattery.charging ? " ⚡" : "")
                    color: pods.hasBattery ? root.ink : root.sumi
                    topPadding: 4; bottomPadding: 4
                }
                MenuText {
                    width: parent.width
                    visible: pods.actionStatus !== ""
                    text: pods.actionStatus
                    wrapMode: Text.WordWrap
                    color: root.seal
                }
                Repeater {
                    model: pods.hasAirPods ? pods.availableModes() : []
                    MenuButton {
                        required property var modelData
                        text: Model.noiseModeName(modelData)
                        selected: pods.noiseMode === modelData
                        onClicked: pods.setNoiseMode(modelData)
                    }
                }
                Item {
                    visible: pods.hasAirPods && pods.supportsConversationalAwareness
                    width: parent.width; height: 28
                    MenuText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Conversation awareness"
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 46; height: 20; radius: 10
                        color: pods.conversationalAwareness ? root.fillActive : root.fillIdle
                        border.color: pods.conversationalAwareness ? root.seal : root.sep
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Rectangle {
                            width: 14; height: 14; radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            x: pods.conversationalAwareness ? parent.width - width - 3 : 3
                            color: pods.conversationalAwareness ? root.seal : root.sumi
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pods.setConversationalAwareness(!pods.conversationalAwareness)
                        }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: root.sep }
                MenuButton {
                    text: "Close"
                    color: closeAction.containsMouse ? root.fillPrimaryHover : root.seal
                    labelColor: root.paper
                    MouseArea {
                        id: closeAction
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.airpodsVisible = false
                    }
                }
            }
        }
}
