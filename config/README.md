# Config

This directory contains the configuration files needed to patch Firefox.

- `Info.plist` contains Mac app info.
- `application.ini` is the XULRunner configuration file.
- `dsstore` is the layout/sizing configuration for the Mac installer.
- `entitlements.plist` contains permissions required when the Mac app is sandboxed.
- `linux-launcher.desktop` is an application shortcut that makes the executable look pretty in Ubuntu (and other distros that support .desktop files).
- `linux-launcher.sh` is the launcher script for Linux.
- `make_dmg.py` is part of Firefox's packaging system that has been modified to sign the files just before packaging on Mac.
- `mozconfig` contains Firefox build flags.
- `mozilla.cfg` contains Firefox preferences.
- `sqlite-writer.js` tells Firefox where to find the preferences file.
