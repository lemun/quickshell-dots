# Shai's AirPods fork

This fork adds an AirPods icon beside Bluetooth in V1 and V2, with battery
levels, supported listening modes, conversation awareness, and right-click mode
cycling. Its panel uses the shared popup lifecycle. In V2 it uses the connected
panel surface and bar animation. No separate restoration patch is needed.

## Install on another Omarchy box

```bash
git clone https://github.com/lemun/quickshell-dots.git
cd quickshell-dots
bash install.sh V2 --autostart --no-ai-backend --profile=shai
```

`--profile=shai` restores the saved widget selection, layout, and appearance.
It backs up previous preferences. Omit it to keep that machine's preferences.
The bar follows the machine's current Omarchy theme. Monitor configuration,
wallpapers, credentials, Bluetooth pairing keys, and other desktop settings
are not part of this bar profile. Pair your AirPods independently on each box.

The AirPods daemon is a separate dependency:

```bash
omarchy plugin add https://github.com/thisisgm/omarchy-pods --enable
~/.config/omarchy/plugins/io.github.thisisgm.omapods/setup
```

The icon stays visible and displays a service/disconnected message until the
daemon and paired AirPods are available. Building the daemon may request package
installation privileges. These commands run the upstream plugin's setup.

To reapply only the personal preferences from this checkout:

```bash
python3 scripts/qs-apply-profile.py shai
```

## Keep the fork updated

Use `origin` for this fork and `upstream` for the original project:

```bash
git remote add upstream https://github.com/HANCORE-linux/quickshell-dots.git
git switch main
git pull --ff-only origin main
git fetch upstream
git merge upstream/main
# Resolve any conflicts, then run the repository checks described in development.md.
git push origin main
```

Add `upstream` only once. A merge preserves the AirPods commits; overlapping
upstream changes may need manual conflict resolution. Do not reset main to
upstream/main or force-sync the fork, since that discards the customization.

Each box's bar updater fetches `origin/main` from the deploy clone at
`~/.local/share/quickshell-dots`, which the fork installer configures to use
`lemun/quickshell-dots`. After pushing a merged version, use the bar's update
panel on each box. The updater keeps its existing smoke checks, backups, and
rollback behavior. Upstream changes reach your machines after you merge and
push them to the fork, rather than overwriting your branch automatically.

## Attribution

AirPodsService.qml and Model.js are adapted from thisisgm/omarchy-pods commit
fff7fec600a5b9a61cdb40e93eccbcceb4b8f824 (MIT, copyright 2026 GM).
The license is preserved at licenses/omarchy-pods-MIT.txt. The icon in this fork
is an original geometric drawing. The separate daemon is upstream librepods
under GPL-3.0 and is installed independently; it is not copied into this fork.
