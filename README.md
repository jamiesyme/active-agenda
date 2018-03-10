# SQLite Writer

## Setup

First, install the tools that are specified per OS below. Afterwards, run:

```bash
./control.sh setup
```

**Note:** you may be asked to enter your password to install packages.

**Note:** on Windows, `control.sh` is expected to be run using the shell provided by MozillaBuild.

### Linux

Tools:

- build-essentials (gcc, make, etc)
- curl or wget
- python2
- rust

### Mac

Tools:

- rust
- Xcode

If you just installed Xcode, make you sure you start it to finish the setup, and then run:

```bash
sudo xcode-select --switch /Applications/Xcode.app
```

### Windows

Tools:

- Visual Studio Community 2015 with Update 3 ([link](https://www.visualstudio.com/vs/older-downloads/))
	- Check "Programming Languages -> Visual C++ -> Common Tools for Visual C++ 2015" during install
	- Uncheck "Windows and Web Development -> (all)" during install
- Rust
- MozillaBuild ([direct link](https://ftp.mozilla.org/pub/mozilla.org/mozilla/libraries/win32/MozillaBuildSetup-Latest.exe))

## Building

To build:

```bash
./control.sh build
```

To package:

```bash
./control.sh package
```

The packaged app can be found in `build/`.

## Customizing the Mac Installer

If you need to update the background image, then editing `icons/mac/background.png` will do just fine (make sure the image has 72 dpi). However, if you need to change any sizing or positioning of items in the installer, you'll need to create a new `config/dsstore`.

First, build and package the application normally. The package generated is read-only, so convert it to read-write using:

```bash
hdiutil convert -format UDRW -o "build/SQLite Writer 0.0.0 rw.dmg" "build/SQLite Writer 0.0.0.dmg"
```

Next, attach the disk image:

```bash
hdiutil attach "build/SQLite Writer 0.0.0 rw.dmg"
```

This will automatically open the installer (which is really just a Finder window without the toolbars); close this for now.

Open up Finder and select "SQLite Writer" from the "Devices" menu (also found at `/Volumes/SQLite Writer`). From here, you can move the icons, change the folder background, etc.

When finished editing the folder, we need to fix the size of the window, which we cannot do from Finder, as the minimum window size for Finder is larger than our background image. So go ahead and reattach the disk image using:

```bash
hdiutil detach "/Volumes/SQLite Writer"
hdiutil attach "build/SQLite Writer 0.0.0 rw.dmg"
```

This will automatically open the installer window again, but it will likely have the wrong dimensions; don't close the window this time. Open up the Script Editor (found in `/Applications/Utilities`) and paste the following:

```applescript
tell application "Finder"
	activate
	reopen
	set the bounds of the first window to {0, 0, 512, 320}
end tell
```

**Important:** Make sure that any Finder windows that are open are not viewing the SQLite Writer device, as this could potentially overwrite what we're trying to do. Also, make sure the installer window (the one that opened automatically) was the last active window (besides the Script Editor) before you run the script, otherwise this command might resize the wrong window.

Run the script using the play button. This will resize the installer window to the correct dimensions, which will get saved to the `.DS_Store` file. Now you can close the installer window.

Finally, save the new `.DS_Store`, detach the disk image, delete the temporary disk image, and rebuild/repackage the app:

```bash
cp "/Volumes/SQLite Writer/.DS_Store" config/dsstore
hdiutil detach "/Volumes/SQLite Writer"
rm "build/SQLite Writer 0.0.0 rw.dmg"
rm -rf build/source
./control.sh build
./control.sh package
```
