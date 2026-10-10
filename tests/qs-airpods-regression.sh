#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp "$repo/versions/V1/core/"{AirPodsService.qml,Model.js} "$work/"
mkdir -p "$work/state/librepods"
printf '{"schema_version":1,"connected":false}\n' > "$work/state/librepods/status.json"
cat > "$work/ctl" <<'CTL'
#!/usr/bin/env bash
printf '%s\n' "$1" >> "$XDG_STATE_HOME/commands"
sleep 0.05
if [[ "$1" == noise:anc ]]; then
  echo 'test rejection' >&2
  exit 1
fi
CTL
chmod +x "$work/ctl"
cat > "$work/test.qml" <<'QML'
import QtQuick
import Quickshell
import "Model.js" as Model
Item {
    AirPodsService { id: pods; settings: ({ctlPath: Qt.resolvedUrl("ctl").toString().replace("file://", "")}) }
    property int step: 0
    function check(ok, detail) { if (!ok) { console.error("AIRPODS_FAIL " + detail); Qt.quit(); throw new Error(detail) } }
    function status(extra) {
        return JSON.stringify(Object.assign({schema_version: 1, connected: true,
            is_pro_series: true, supports_adaptive: true, supports_conversational_awareness: true,
            left: {available:true, level:79, charging:false},
            right: {available:true, level:100, charging:true},
            case: {available:true, level:50, charging:true}, noise_mode:0}, extra || {}))
    }
    Timer {
        interval: 180; running: true; repeat: true
        onTriggered: {
            if (step === 0) {
                pods.applyLine(status())
                check(pods.hasBattery && pods.rightPod.charging && pods.caseBattery.level === 50, "batteries")
                pods.applyLine(status({connected:false}))
                check(!pods.hasAirPods && pods.hasBattery, "disconnected BLE battery")
                pods.setNoiseMode(Model.NOISE_ANC)
                check(!pods.busy, "disconnected command guard")
                pods.applyLine('{"schema_version":99}')
                check(pods.schemaUnsupported && !pods.hasBattery && pods.lastError !== "", "schema clears stale battery")
                pods.applyLine(status())
                pods.applyLine("bad json")
                check(!pods.hasBattery && !pods.connected && pods.lastError !== "", "malformed status")
                pods.applyLine(status({supports_noise_control:false}))
                pods.cycleNoiseMode()
                check(!pods.busy && pods.availableModes().length === 0, "unsupported mode guard")
                pods.applyLine(status({supports_noise_off:false}))
                pods.cycleNoiseMode()
                check(pods.noiseMode === Model.NOISE_TRANSPARENCY, "capability-aware cycle")
                pods.setConversationalAwareness(true)
            } else if (step === 1) {
                check(!pods.busy && pods.conversationalAwareness, "queued command completes")
                pods.applyLine(status())
                check(pods.conversationalAwareness, "optimistic hold")
                pods.setNoiseMode(Model.NOISE_ANC)
            } else if (step === 2) {
                check(pods.actionStatus === "test rejection" && pods._pendingField === "", "command rejection")
                pods.applyLine(status({is_headset:true, headset:{available:true,level:42,charging:true}}))
                check(pods.hasBattery && pods.headsetBattery.level === 42, "Max battery")
                pods.stateGone()
                check(!pods.daemonReachable && !pods.hasBattery && !pods.connected, "service disappears")
                console.log("AIRPODS_PASS")
                Qt.quit()
            }
            step++
        }
    }
}
QML
XDG_STATE_HOME="$work/state" QT_QPA_PLATFORM=offscreen timeout 8 qs -p "$work/test.qml" > "$work/log" 2>&1 || { cat "$work/log"; exit 1; }
grep -q AIRPODS_PASS "$work/log" || { cat "$work/log"; exit 1; }
printf 'noise:transparency\nca:on\nnoise:anc\n' > "$work/expected"
diff -u "$work/expected" "$work/state/commands"
python3 "$repo/scripts/qs-apply-profile.py" shai --home "$work/home" >/dev/null
printf 'original\n' > "$work/home/.cache/quickshell_widgets_v2"
python3 "$repo/scripts/qs-apply-profile.py" shai --home "$work/home" >/dev/null
cmp "$repo/profiles/shai/quickshell_widgets_v2" "$work/home/.cache/quickshell_widgets_v2"
backup=("$work/home/.local/state/quickshell-rise/profile-backups/"*/quickshell_widgets_v2)
grep -qx original "${backup[0]}"
printf 'PASS: AirPods service, commands, and portable profile\n'
