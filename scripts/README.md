# Scripts

This directory contains the various scripts that power the `control.sh` script in the project root.

- `bootstrap.sh` downloads/installs the various libraries and tools required to build the app. See the section below for details.
- `common.sh` contains common functions and variables used across all the scripts. If you're trying to find variables to tweak the build the build system, this would be a good place to start.
- `compile.sh` compiles the (patched) Firefox source code.
- `detect-os.sh` detects the operating system using the bash variable `$OSTYPE`.
- `download.sh` downloads and extracts the Firefox source code using either wget or curl.
- `package.sh` packages the app after it's been compiled and puts the package in the build directory.
- `patch-build.sh` patches the Firefox build (after compilation), which basically involves installing Active Agenda and the app launcher.
- `patch-source.sh` patches the Firefox source (before compilation), which includes things like setting the build flags, replacing brand names, and replacing icons.

## bootstrap.sh

This script downloads/installs the various libraries and tools required to build the app. It used only by `control.sh setup`.

**Note:** this script expects some tools to be installed already. These instructions differ per OS. See the readme in the root of the repo.
