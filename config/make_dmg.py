# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import print_function

from mozbuild.base import MozbuildObject
from mozpack import dmg

import os
import sys


def print_flush(s):
    print(s)
    sys.stdout.flush()

def make_dmg(source_directory, output_dmg):
    build = MozbuildObject.from_environment()
    extra_files = [
        (os.path.join(build.distdir, 'branding', 'dsstore'), '.DS_Store'),
        (os.path.join(build.distdir, 'branding', 'background.png'),
         '.background/background.png'),
        (os.path.join(build.distdir, 'branding', 'disk.icns'),
         '.VolumeIcon.icns'),
    ]
    volume_name = build.substs['MOZ_APP_DISPLAYNAME']

    print_flush('Removing extended file attributes ...')
    os.system('xattr -cr SQLiteWriter.app')

    print_flush('Unlocking keychain for signing ...')
    os.system('security unlock-keychain -p "$SIGNING_PASSWORD" "$HOME/Library/Keychains/login.keychain-db"')
    os.system('security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$SIGNING_PASSWORD" "$HOME/Library/Keychains/login.keychain-db"')
    os.system('security set-keychain-settings "$HOME/Library/Keychains/login.keychain-db"')

    need_signing = [
        'SQLiteWriter.app/Contents/MacOS/crashreporter.app/Contents/MacOS/minidump-analyzer',
        'SQLiteWriter.app/Contents/MacOS/crashreporter.app',
        'SQLiteWriter.app/Contents/MacOS/plugin-container.app',
        'SQLiteWriter.app/Contents/MacOS/*.dylib',
        'SQLiteWriter.app/Contents/MacOS/pingsender',
        'SQLiteWriter.app/Contents/MacOS/XUL',
        'SQLiteWriter.app/Contents/MacOS/sqlite-writer-bin',
        'SQLiteWriter.app/Contents/Resources/gmp-clearkey/0.1/libclearkey.dylib',
        'SQLiteWriter.app',
    ]
    for rel_path in need_signing:
        print_flush('Signing ' + rel_path + ' ...')
        abs_path = os.path.join(os.getcwd(), source_directory, rel_path)
        os.system('codesign --force --sign "$SIGNING_IDENTITY_A" --entitlements "$SIGNING_ENTITLEMENTS" --requirements "=designated => anchor apple generic" ' + abs_path)

    print_flush('Testing signing...')
    os.system('codesign -vvvv ' + os.path.join(os.getcwd(), source_directory, 'SQLiteWriter.app'))

    print_flush('Testing attributes...')
    os.system('xattr -cr SQLiteWriter.app')
    print_flush('(done testing attributes)')

    dmg.create_dmg(source_directory, output_dmg, volume_name, extra_files)


def main(args):
    if len(args) != 2:
        print('Usage: make_dmg.py <source directory> <output dmg>',
              file=sys.stderr)
        return 1
    make_dmg(args[0], args[1])
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
