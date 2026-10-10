import QtQuick

// Original geometric earbud/headphone mark; no vendor artwork.
Item {
    id: mark
    property real iconSize: 18
    property color color: "white"
    property string variant: "buds"
    implicitWidth: iconSize
    implicitHeight: iconSize
    Item {
        anchors.centerIn: parent
        width: mark.iconSize; height: mark.iconSize
        visible: mark.variant !== "max"
        Repeater {
            model: 2
            Item {
                required property int index
                x: index === 0 ? parent.width * 0.1 : parent.width * 0.57
                y: parent.height * 0.13
                width: parent.width * 0.33
                height: parent.height * 0.76
                rotation: index === 0 ? -12 : 12
                Rectangle { width: parent.width; height: parent.width; radius: width / 2; color: mark.color }
                Rectangle { x: parent.width * 0.4; y: parent.width * 0.55; width: parent.width * 0.38; height: parent.height * 0.66; radius: width / 2; color: mark.color }
            }
        }
    }
    Item {
        anchors.centerIn: parent
        width: mark.iconSize; height: mark.iconSize
        visible: mark.variant === "max"
        Rectangle { x: width * 0.1; y: height * 0.05; width: parent.width * 0.8; height: parent.height * 0.8; radius: width / 2; color: "transparent"; border.color: mark.color; border.width: Math.max(1, mark.iconSize * 0.1) }
        Rectangle { x: 0; y: parent.height * 0.4; width: parent.width * 0.25; height: parent.height * 0.5; radius: width / 3; color: mark.color }
        Rectangle { x: parent.width * 0.75; y: parent.height * 0.4; width: parent.width * 0.25; height: parent.height * 0.5; radius: width / 3; color: mark.color }
    }
}
