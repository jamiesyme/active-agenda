#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"

download_url="https://archive.mozilla.org/pub/firefox/releases/$FF_VERSION/source/firefox-$FF_VERSION.source.tar.xz"
file=firefox-source.tar.xz

if command -v wget >/dev/null 2>&1 ; then
	download_cmd="wget -O"
elif command -v curl >/dev/null 2>&1 ; then
	download_cmd="curl -o"
else
	error_exit "Cannot find wget or curl"
fi

mkdir -p "$FF_SOURCE_DIR"
cd "$REPO_BUILD_DIR"

log "Downloading Firefox source"
$download_cmd "$file" "$download_url"

log "Unpacking Firefox source"
if [[ "$BUILD_OS" = "windows" ]] ; then
	tar -xf "$file" --directory "$FF_SOURCE_DIR" --strip-components=1 --exclude="testing/mozharness/configs/single_locale/linux32_devedition.py" --exclude="testing/mozharness/configs/single_locale/linux32.py"
else
	tar -xf "$file" --directory "$FF_SOURCE_DIR" --strip-components=1
fi

rm "$file"
