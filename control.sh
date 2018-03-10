#!/usr/bin/env bash
set -euo pipefail

# To see what variables can be configured, see `scripts/set-defaults.sh`

SIGNING_IDENTITY_A='3rd Party Mac Developer Application: Adrien Gilmore (7BUQJW3EMM)'
SIGNING_IDENTITY_I='3rd Party Mac Developer Installer: Adrien Gilmore (7BUQJW3EMM)'
SW_VERSION=1.3.10

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_SCRIPTS_DIR="$REPO_DIR/scripts"
. "$REPO_SCRIPTS_DIR/common.sh"

case "$1" in
	setup)
		log "Setup started."

		if [ ! "$(ls -A "$FF_SOURCE_DIR" 2>/dev/null)" ] ; then
			download=$(ask_yes_no "The Firefox source is required for setup. Download now (y/n)? ")

			if [ "$download" = "yes" ] ; then
				log "Downloading now..."
				"$REPO_SCRIPTS_DIR/download.sh" || error_exit "Failed to download Firefox source."
				log "Firefox source downloaded."
			else
				error_exit "Setup aborted."
			fi
		fi

		log "Running bootstrap..."
		"$REPO_SCRIPTS_DIR/bootstrap.sh" || error_exit "Failed to bootstrap."
		log "Bootstrap finished."

		log "Setup was successful."
		;;

	build)
		log "Build started."

		if [ ! "$(ls -A "$FF_SOURCE_DIR" 2>/dev/null)" ] ; then
			download=$(ask_yes_no "Firefox source is missing. Download now (y/n)? ")

			if [ "$download" = "yes" ] ; then
				log "Downloading now..."
				"$REPO_SCRIPTS_DIR/download.sh" || error_exit "Failed to download Firefox source."
				log "Firefox source downloaded."
			else
				error_exit "Build aborted."
			fi
		fi

		log "Patching Firefox source..."
		"$REPO_SCRIPTS_DIR/patch-source.sh" || error_exit "Failed to patch Firefox source."
		log "Patched Firefox source."

		log "Compiling Firefox source... (this will take awhile)"
		"$REPO_SCRIPTS_DIR/compile.sh" || error_exit "Failed to compile Firefox source."
		log "Compiled Firefox source."

		log "Patching Firefox build..."
		"$REPO_SCRIPTS_DIR/patch-build.sh" || error_exit "Failed to patch Firefox build."
		log "Patched Firefox build."

		log "Build was successful."
		;;

	package)
		if [ "$BUILD_OS" = "mac" ] ; then
			log "Packaging for mac involves code signing. In order to do this, we'll need access to the keychain."
			stty -echo
			printf "Password: "
			read SIGNING_PASSWORD
			stty echo
			printf "\n"
		fi
		log "Packaging started."
		"$REPO_SCRIPTS_DIR/package.sh" || error_exit "Failed to package."
		log "Packaging was successful; see build/ directory."
		;;

	*)
		cat >&2 <<EOF
Usage: $(basename $0) command
Commands:
  setup         Install packages needed to build Firefox.
  build         Download, patch, compile, and configure Firefox as SQLite
                Writer.
  package       Package the app either as an installer (Mac/Windows) or as a
                tarball (Linux).
EOF
		exit 1
		;;
esac
