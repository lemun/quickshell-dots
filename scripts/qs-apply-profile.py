#!/usr/bin/env python3
"""Apply a named, portable bar profile with a backup of existing preferences."""
import argparse
from pathlib import Path
import shutil
from datetime import datetime

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('profile', choices=['shai'])
parser.add_argument('--home', type=Path, default=Path.home())
args = parser.parse_args()
source = Path(__file__).resolve().parents[1] / 'profiles' / args.profile
home = args.home
files = {
    'quickshell_widgets_v2': home / '.cache/quickshell_widgets_v2',
    'quickshell_barorder_v2': home / '.cache/quickshell_barorder_v2',
}
# New snapshots can also carry V1 preferences; older V2-only profiles still work.
for name in ('quickshell_widgets', 'quickshell_barorder'):
    if (source / name).is_file():
        files[name] = home / '.cache' / name
backup = home / '.local/state/quickshell-rise/profile-backups' / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
# Validate the entire profile before writing preferences.
for name in files:
    if not (source / name).is_file():
        raise SystemExit('Profile is missing ' + name)
for name, target in files.items():
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        backup.mkdir(parents=True, exist_ok=True)
        shutil.copy2(target, backup / name)
    shutil.copy2(source / name, target)
print('Applied profile:', args.profile)
if backup.exists():
    print('Previous preferences:', backup)
