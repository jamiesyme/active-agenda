#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

if [[ "$BUILD_OS" = "mac" ]] ; then
	ff_dist_bin_dir="$FF_DIST_DIR/ActiveAgenda.app/Contents/MacOS"
	ff_dist_res_dir="$FF_DIST_DIR/ActiveAgenda.app/Contents/Resources"
else
	ff_dist_bin_dir="$FF_DIST_DIR/bin"
	ff_dist_res_dir="$FF_DIST_DIR/bin"
fi


log "Removing extra binary"

rm -f "$ff_dist_bin_dir/active-agenda-bin-bin"


# Install launcher (if necessary).

if [[ "$BUILD_OS" = "linux" ]] ; then
	log "Installing launcher"
	cp "$REPO_CONFIG_DIR/linux-launcher.sh" "$ff_dist_bin_dir/active-agenda"
	cp "$REPO_CONFIG_DIR/linux-launcher.desktop" "$ff_dist_bin_dir/active-agenda.desktop"
fi
