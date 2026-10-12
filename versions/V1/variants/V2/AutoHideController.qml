import QtQuick

// Per-output visibility state. Popups and layout editing keep the bar reachable.
QtObject {
    id: controller
    property bool enabled: false
    property bool hovered: false
    property bool held: false
    property int hideDelay: 350
    property bool revealed: false
    readonly property bool shown: !enabled || revealed || held

    function update() {
        hideTimer.stop()
        if (!enabled) revealed = false
        else if (hovered || held) revealed = true
        else if (revealed) hideTimer.restart()
    }
    onEnabledChanged: update()
    onHoveredChanged: update()
    onHeldChanged: update()
    property Timer hideTimer: Timer {
        interval: controller.hideDelay
        onTriggered: if (!controller.hovered && !controller.held) controller.revealed = false
    }
}
