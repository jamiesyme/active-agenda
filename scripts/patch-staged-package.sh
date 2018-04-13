#!/usr/bin/env bash
set -euo pipefail

# Expects rel path to staging dir to be passed as the first and only parameter.
# This path is relative to the DIST dir, and is typically 'active-agenda-bin',
# but is determined by the moz build system.


REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

if [[ "$BUILD_OS" = "mac" ]] ; then
	ff_dist_bin_dir="$FF_DIST_DIR/$1/Contents/MacOS"
	ff_dist_res_dir="$FF_DIST_DIR/$1/Contents/Resources"
else
	ff_dist_bin_dir="$FF_DIST_DIR/$1"
	ff_dist_res_dir="$FF_DIST_DIR/$1"
fi


log "Patching staged package"

aa_cp_dir="$ff_dist_res_dir/browser"
cp "$AA_SOURCE_DIR/chrome.manifest" "$aa_cp_dir"
