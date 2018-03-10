#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

case "$BUILD_OS" in
	linux)
		cd "$FF_SOURCE_DIR"
		./mach package | tee "$REPO_BUILD_DIR/package.log"

		# Many people expect the root directory of a tarball to match
		# the basename, so we'll repackage the tarball to follow that
		# convention.
		log "Patching package"
		cd "$REPO_BUILD_DIR"
		src="$FF_DIST_DIR/sqlite-writer-bin-$SW_VERSION.en-US.linux-x86_64.tar.bz2"
		dest="sqlite-writer-${SW_VERSION}"
		mkdir -p "$dest"
		tar -xf "$src" --strip-components=1 -C "$dest"
		tar -cjf "$dest.tar.bz2" "$dest"
		rm -rf "$dest"
		;;

	mac)
		cd "$FF_SOURCE_DIR"
		./mach package | tee "$REPO_BUILD_DIR/package.log"
		cp "$FF_DIST_DIR/sqlite-writer-bin-$SW_VERSION.en-US.mac.dmg" "$REPO_BUILD_DIR/SQLite Writer $SW_VERSION.dmg"

		log "Building .pkg for app store"
		keychain="$HOME/Library/Keychains/login.keychain-db"
		src="$FF_DIST_DIR/sqlite-writer-bin/SQLiteWriter.app"
		dest="$REPO_BUILD_DIR/SQLite Writer $SW_VERSION.pkg"
		security unlock-keychain -p "$SIGNING_PASSWORD" "$keychain"
		security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$SIGNING_PASSWORD" "$keychain"
		security set-keychain-settings "$keychain"
		productbuild --sign "$SIGNING_IDENTITY_I" --component "$src" '/Applications' "$dest"
		;;

	windows)
		cd "$FF_SOURCE_DIR"
		./mach build installer | tee "$REPO_BUILD_DIR/package.log"
		cp "$FF_DIST_DIR/install/sea/sqlite-writer-bin-$SW_VERSION.en-US.win32.installer.exe" "$REPO_BUILD_DIR/SQLite Writer Setup $SW_VERSION.exe"
		;;

	*)
		error_exit "Unrecognized or unsupported OS: $BUILD_OS"
esac
