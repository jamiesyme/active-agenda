#!/usr/bin/env bash
set -euo pipefail

# Variables:
#   REPO_DIR               Absolute path to root of repo.
#   AA_SOURCE_DIR          (default: $REPO_DIR/active-agenda)
#   AA_VERSION             Active Agenda version (default: 0.0.0)
#   BUILD_OS               OS to build for (note that manually overriding this
#                           will not affect the Mozilla build system, and is
#                           untested; this variable is meant to provide
#                           convenient OS detection for scripts).
#   FF_SOURCE_DIR          Absolute path to directory where Firefox source will
#                           be downloaded to (default: $REPO_DIR/build/source)
#   FF_DIST_DIR            Absolute path to directory where Firefox build will
#                           be (default: $FF_SOURCE_DIR/obj-active-agenda/dist)
#   FF_VERSION             Firefox version (default: 54.0.1)
#   LLVM_CONFIG            Absolute path to llvm-config-* executable
#                           (default: /usr/bin/llvm-config-5.0).
#   REPO_BUILD_DIR         (default: $REPO_DIR/build)
#   REPO_CONFIG_DIR        (default: $REPO_DIR/config)
#   REPO_ICON_DIR          (default: $REPO_DIR/icons)
#   REPO_NSIS_DIR          (default: $REPO_DIR/nsis)
#   REPO_SCRIPTS_DIR       (default: $REPO_DIR/scripts)
#   SIGNING_ENTITLEMENTS   Absolute path to entitlements plist file used to sign
#                           code on macOS
#                           (default: $REPO_CONFIG_DIR/entitlements.plist)
#   SIGNING_IDENTITY_A     Common name of certificate within keychain used to
#                           sign application code on macOS (default: -)
#   SIGNING_IDENTITY_I     Common name of certificate within keychain used to
#                           sign installers on macOS (default: -)
#   SIGNING_PASSWORD       Password for unlocking the keychain to allow code
#                           signing. Only used on macOS (no default).
#
# Functions:
#   log          Logs a message to the console
#   ask_yes_no   Prompts the user for a (y/n)
#   error_exit   Logs a message and exits
#   sedi         Provides uniform interface to `sed -i`, since the behaviour
#                 is different on Mac than it is on Linux


export REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

export AA_SOURCE_DIR="${AA_SOURCE_DIR:-$REPO_DIR/active-agenda}"
export AA_VERSION="${AA_VERSION:-0.0.0}"
export BUILD_OS="${BUILD_OS:-`$REPO_SCRIPTS_DIR/detect-os.sh`}"
export FF_SOURCE_DIR="${FF_SOURCE_DIR:-$REPO_DIR/build/source}"
export FF_DIST_DIR="${FF_DIST_DIR:-$FF_SOURCE_DIR/obj-active-agenda/dist}"
export FF_VERSION="${FF_VERSION:-58.0.2}"
export LLVM_CONFIG="${LLVM_CONFIG:-/usr/bin/llvm-config-5.0}"
export REPO_BUILD_DIR="${REPO_BUILD_DIR:-$REPO_DIR/build}"
export REPO_CONFIG_DIR="${REPO_CONFIG_DIR:-$REPO_DIR/config}"
export REPO_ICON_DIR="${REPO_ICON_DIR:-$REPO_DIR/icons}"
export REPO_NSIS_DIR="${REPO_NSIS_DIR:-$REPO_DIR/nsis}"
export REPO_SCRIPTS_DIR="${REPO_SCRIPTS_DIR:-$REPO_DIR/scripts}"
export SIGNING_ENTITLEMENTS="${SIGNING_ENTITLEMENTS:-$REPO_CONFIG_DIR/entitlements.plist}"
export SIGNING_IDENTITY_A="${SIGNING_IDENTITY_A:--}"
export SIGNING_IDENTITY_I="${SIGNING_IDENTITY_I:--}"
export SIGNING_PASSWORD="${SIGNING_PASSWORD:-}"

log () {
	echo "$(basename $0): $1"
}

ask_yes_no () {
	read -p "$(basename $0): $1" choice
	case "$choice" in
		y|Y) echo "yes" ;;
		n|N) echo "no" ;;
		*) echo "invalid" ;;
	esac
}

error_exit () {
	log "$1"
	exit "${2:-1}"
}

sedi () {
	file="${@: -1}"
	sed "$@" > "$file.tmp" && mv "$file.tmp" "$file"
}
