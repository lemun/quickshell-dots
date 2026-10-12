#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp "$repo/versions/V1/variants/V2/AutoHideController.qml" "$work/"
cat > "$work/test.qml" <<'QML'
import QtQuick
Item {
    AutoHideController { id: bar; hideDelay: 40 }
    AutoHideController { id: other; enabled: true; hideDelay: 40 }
    property int step: 0
    function check(ok, detail) {
        if (!ok) { console.error("AUTOHIDE_FAIL " + detail); Qt.quit(); throw new Error(detail) }
    }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            if (step === 0) {
                check(bar.shown, "legacy settings stay visible")
                bar.enabled = true
                check(!bar.shown, "enabled bar starts hidden")
                bar.hovered = true
                check(bar.shown && !other.shown, "edge reveals only this output")
                bar.hovered = false
                check(bar.shown, "leave allows time to enter a popup")
            } else if (step === 1) {
                check(!bar.shown, "leave hides after delay")
                bar.held = true
                check(bar.shown, "popup or editing reveals")
            } else if (step === 2) {
                check(bar.shown, "popup remains visible without hover")
                bar.held = false
                bar.hovered = true
            } else if (step === 3) {
                check(bar.shown, "return cancels pending hide")
                bar.hovered = false
                bar.enabled = false
            } else if (step === 4) {
                check(bar.shown, "disabling restores always visible")
                console.log("AUTOHIDE_PASS")
                Qt.quit()
            }
            step++
        }
    }
}
QML
mkdir -p "$work/runtime"
chmod 700 "$work/runtime"
XDG_RUNTIME_DIR="$work/runtime" QT_QPA_PLATFORMTHEME=generic QT_QPA_PLATFORM=offscreen timeout 8 qs -p "$work/test.qml" > "$work/log" 2>&1 || { cat "$work/log"; exit 1; }
rg -q AUTOHIDE_PASS "$work/log" || { cat "$work/log"; exit 1; }
printf 'PASS: edge reveal, hide delay, popup hold, output isolation, and opt-out\n'
