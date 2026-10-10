#!/usr/bin/env python3
"""Exercise profile publishing against isolated local Git repositories."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/qs-save-profile'


class SaveProfileTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        root = Path(self.temporary.name)
        self.repo = root / 'repo'
        self.remote = root / 'remote.git'
        self.home = root / 'home'
        self.repo.mkdir()
        self.git('init', '-b', 'main')
        self.git('config', 'user.name', 'Profile Test')
        self.git('config', 'user.email', 'profile@example.invalid')
        (self.repo / 'scripts').mkdir()
        shutil.copy2(SCRIPT, self.repo / 'scripts/qs-save-profile')
        self.profile = self.repo / 'profiles/shai'
        self.profile.mkdir(parents=True)
        for name in ('quickshell_widgets_v2', 'quickshell_barorder_v2'):
            (self.profile / name).write_text('old\n')
            target = self.home / '.cache' / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text('new\n')
        (self.profile / 'active-variant').write_text('v1\n')
        self.controller = self.home / '.config/quickshell/bin/qs-barctl'
        self.controller.parent.mkdir(parents=True)
        self.controller.write_text('#!/bin/sh\nprintf "v2\\n"\n')
        self.controller.chmod(0o755)
        self.git('add', '.')
        self.git('commit', '-m', 'initial')
        subprocess.run(['git', 'init', '--bare', '-b', 'main', str(self.remote)],
                       check=True, capture_output=True)
        # Keep the fork URL validation while routing all transport to a local fixture.
        fork = 'https://github.com/lemun/quickshell-dots.git'
        self.git('config', f'url.{self.remote}.insteadOf', fork)
        self.git('remote', 'add', 'origin', fork)
        self.git('push', '-u', 'origin', 'main')

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.repo), *args], check=True,
                              text=True, capture_output=True).stdout.strip()

    def save(self):
        return subprocess.run([str(self.repo / 'scripts/qs-save-profile'),
                               '--home', str(self.home)], text=True, capture_output=True)

    def test_save_publish_backup_and_no_change(self):
        result = self.save()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.profile / 'active-variant').read_text(), 'v2\n')
        self.assertEqual((self.profile / 'quickshell_widgets_v2').read_text(), 'new\n')
        remote_head = subprocess.check_output(['git', '--git-dir', str(self.remote),
                                              'rev-parse', 'main'], text=True).strip()
        self.assertEqual(self.git('rev-parse', 'HEAD'), remote_head)
        backup = list((self.home / '.local/state/quickshell-rise/profile-backups').glob('*'))
        self.assertEqual(len(backup), 1)
        self.assertEqual((backup[0] / 'quickshell_widgets_v2').read_text(), 'old\n')
        head = self.git('rev-parse', 'HEAD')
        self.assertEqual(self.save().returncode, 0)
        self.assertEqual(self.git('rev-parse', 'HEAD'), head)
        self.assertEqual(self.git('status', '--porcelain'), '')

    def test_v1_preferences_are_saved_with_the_active_variant(self):
        for name in ('quickshell_widgets', 'quickshell_barorder'):
            (self.home / '.cache' / name).write_text('v1 custom\n')
        self.controller.write_text('#!/bin/sh\nprintf "v1\\n"\n')
        result = self.save()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.profile / 'active-variant').read_text(), 'v1\n')
        self.assertEqual((self.profile / 'quickshell_widgets').read_text(), 'v1 custom\n')
        apply = SCRIPT.parent / 'qs-apply-profile.py'
        shutil.copy2(apply, self.repo / 'scripts/qs-apply-profile.py')
        other_home = self.home.parent / 'other-home'
        subprocess.run(['python3', str(self.repo / 'scripts/qs-apply-profile.py'),
                        'shai', '--home', str(other_home)], check=True, capture_output=True)
        self.assertEqual((other_home / '.cache/quickshell_widgets').read_text(), 'v1 custom\n')
        self.assertEqual((other_home / '.cache/quickshell_widgets_v2').read_text(), 'new\n')

    def test_dirty_checkout_is_preserved(self):
        (self.profile / 'active-variant').write_text('user edit\n')
        self.assertNotEqual(self.save().returncode, 0)
        self.assertEqual((self.profile / 'active-variant').read_text(), 'user edit\n')

    def test_wrong_origin_is_rejected(self):
        self.git('remote', 'set-url', 'origin', 'https://github.com/HANCORE-linux/quickshell-dots.git')
        result = self.save()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('origin must point', result.stderr)
        self.assertEqual((self.profile / 'active-variant').read_text(), 'v1\n')

    def test_missing_preferences_and_stopped_bar_are_rejected(self):
        target = self.home / '.cache/quickshell_widgets_v2'
        target.unlink()
        self.assertNotEqual(self.save().returncode, 0)
        target.write_text('new\n')
        self.controller.write_text('#!/bin/sh\nprintf "stopped\\n"\n')
        self.assertNotEqual(self.save().returncode, 0)
        self.assertEqual(self.git('status', '--porcelain'), '')

    def test_failed_push_can_be_retried_without_another_commit(self):
        hook = self.remote / 'hooks/pre-receive'
        hook.write_text('#!/bin/sh\nexit 1\n')
        hook.chmod(0o755)
        self.assertNotEqual(self.save().returncode, 0)
        head = self.git('rev-parse', 'HEAD')
        self.assertEqual((self.profile / 'active-variant').read_text(), 'v2\n')
        hook.unlink()
        self.assertEqual(self.save().returncode, 0)
        self.assertEqual(self.git('rev-parse', 'HEAD'), head)


if __name__ == '__main__':
    unittest.main()
