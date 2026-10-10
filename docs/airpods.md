# Shai's AirPods fork

This fork adds an AirPods icon beside Bluetooth in V1 and V2, with battery
levels, supported listening modes, conversation awareness, and right-click mode
cycling. Its panel uses the shared popup lifecycle. In V2 it uses the connected
panel surface and bar animation. No separate restoration patch is needed.

## Save your current customization as the default

After changing the bar settings, run this one command:

```bash
~/Work/quickshell-dots/scripts/qs-save-profile
```

It updates the checkout from your fork, backs up the previous saved default,
captures your current widgets, layout, appearance settings, and active V1/V2
variant, then commits and pushes them to `lemun/quickshell-dots`. If nothing
changed, it simply syncs the fork. Run it whenever you want your latest changes
to become the default for future installations.

The checkout must be on `main` with no uncommitted changes. Git push access to
your fork must already be configured. If a push fails, the saved commit stays
local; resolve the connection or Git error and rerun the same command.

This saves bar preferences. The Omarchy desktop theme, pairing keys, and account
credentials are configured separately. Existing machines keep their preferences
until you explicitly reapply the profile using the command below.

## Restore Shai's bar on another Omarchy installation

Run these commands in a terminal on the new machine. The saved `shai` profile
matches the layout and appearance preferences verified on Shai's machine on
2026-10-10. This is the Quickshell Rise bar; the installer starts it at login
and handles the stock Omarchy bar through its existing integration.

### 1. Install the bar and saved customization

```bash
mkdir -p ~/Work
cd ~/Work
git clone https://github.com/lemun/quickshell-dots.git
cd quickshell-dots
bash install.sh --autostart --no-ai-backend --profile=shai
```

If the checkout already exists, run `git pull --ff-only origin main` inside it
instead of cloning again, then run the installer command.

`--profile=shai` restores the saved widgets, their order, spacing, bar shape,
position, and appearance settings. It backs up previous preferences and selects your saved V1/V2 variant.
`--autostart` enables login startup, and
`--no-ai-backend` skips installing account usage backends. The profile does not
copy account credentials; account-dependent widgets need their own setup.

With no explicit V1/V2 argument, the installer uses the profile's saved
variant (currently V2). An explicit V1 or V2 argument takes precedence. Omit `--profile=shai` when
you want to keep the new machine's existing bar preferences.

### 2. Match the colors

The bar follows the active Omarchy theme. Shai's theme at verification was
**Matrix**. To use the same colors:

```bash
omarchy theme set Matrix
```

If Matrix is not installed, install it first, then select it:

```bash
omarchy theme install https://github.com/BVisagie/omarchy-matrix-theme
omarchy theme set Matrix
```

You can choose another theme and keep the same bar layout. Wallpapers and
monitor configuration are separate from this bar profile.

### 3. Install the AirPods daemon

The AirPods UI is already included in the fork. Its daemon is a separate
installation:

```bash
omarchy plugin add https://github.com/thisisgm/omarchy-pods --enable
~/.config/omarchy/plugins/io.github.thisisgm.omapods/setup
```

The setup command builds and installs the daemon and enables its user service.
It may request your password to install build dependencies.

Pair and connect your AirPods using the new machine's Bluetooth settings.
Pairing keys are not included in the profile. Left-click the AirPods icon next
to Bluetooth to see batteries and supported controls. Right-click cycles
supported listening modes. The icon remains visible when disconnected; an
unavailable-service message means the daemon needs attention.

### 4. Check the installation

```bash
~/.config/quickshell/bin/qs-barctl status
systemctl --user is-active librepods.service
git -C ~/.local/share/quickshell-dots remote get-url origin
```

Expected results are your saved variant (`v2` initially), `active`, and
`https://github.com/lemun/quickshell-dots.git`. After connecting your AirPods,
open the panel and check that battery values appear. Battery availability and
listening controls depend on the AirPods model and what the daemon reports.

If the daemon is unavailable:

```bash
systemctl --user restart librepods.service
journalctl --user -u librepods.service -n 50 --no-pager
```

## Reapply the saved layout later

From the fork checkout, this restores only preferences and backs up your
current ones. It does not switch variants or change the desktop theme:

```bash
python3 scripts/qs-apply-profile.py shai
```

Profile backups are saved under
`~/.local/state/quickshell-rise/profile-backups/`. The profile is a saved
snapshot; run `qs-save-profile` after later adjustments to publish a new default.

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
