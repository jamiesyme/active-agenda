#!/usr/bin/env bash
set -euo pipefail

REPO_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$REPO_SCRIPTS_DIR/common.sh"


log "Patching SQLite flags"

# Firefox uses SQLite internally, and we need it compiled with the following
# flags:
#   SQLITE_ENABLE_JSON1
#   SQLITE_ENABLE_RTREE
# We can do that by editing the build file for SQLite before building Firefox.

echo 'DEFINES["SQLITE_ENABLE_JSON1"] = True' >> "$FF_SOURCE_DIR/db/sqlite3/src/moz.build"
echo 'DEFINES["SQLITE_ENABLE_RTREE"] = True' >> "$FF_SOURCE_DIR/db/sqlite3/src/moz.build"


log "Patching branding"

# We will use the unofficial Firefox branding as a base.

ff_branding_dir="$FF_SOURCE_DIR/browser/branding/sqlite-writer"
cp -r "$FF_SOURCE_DIR/browser/branding/unofficial" "$ff_branding_dir"

# Update any references to "Firefox" or "Mozilla", and overwrite branding
# images. Note that some windows installer files (.nsi) are patched in this
# section.

sedi 's/"Nightly"/"SQLite Writer"/'        "$ff_branding_dir/locales/en-US/brand.dtd"
sedi 's/=Nightly/=SQLite Writer/'          "$ff_branding_dir/locales/en-US/brand.properties"
sedi 's/"Mozilla"/"Teracet"/'                "$ff_branding_dir/locales/en-US/brand.dtd"
sedi 's/=Mozilla/=Teracet/'                  "$ff_branding_dir/locales/en-US/brand.properties"
sedi 's/Nightly/"SQLite Writer"/'          "$ff_branding_dir/configure.sh"
echo 'MOZ_APP_NAME="sqlite-writer-bin"' >> "$ff_branding_dir/configure.sh" # Is this only needed on Windows?

if [[ "$BUILD_OS" = "mac" ]] ; then
	#echo 'MOZ_MACBUNDLE_NAME="SQLite Writer.app"' >> "$BRANDING_DIR/configure.sh" # Doesn't work
	cp "$REPO_CONFIG_DIR/dsstore" "$ff_branding_dir/dsstore"
	cp "$REPO_ICON_DIR/mac/background.png" "$ff_branding_dir/background.png"
	cp "$REPO_ICON_DIR/mac/firefox.icns" "$ff_branding_dir/firefox.icns"
fi

if [[ "$BUILD_OS" = "windows" ]] ; then
	sedi 's/"Mozilla Developer Preview"/"SQLite Writer"/' "$ff_branding_dir/branding.nsi"
	sedi 's/"mozilla.org"/"teracet.com"/'                   "$ff_branding_dir/branding.nsi"

	ff_nsis_dir="$FF_SOURCE_DIR/browser/installer/windows/nsis"
	sedi 's/Mozilla Firefox/SQLite Writer/'                  "$ff_nsis_dir/../app.tag"
	sedi 's/FirefoxMessageWindow/SQLiteWriterMessageWindow/' "$ff_nsis_dir/defines.nsi.in"
	sedi 's/Firefox/SQLite Writer/'                          "$ff_nsis_dir/defines.nsi.in"
	sedi 's/\\Mozilla/\\Teracet/'                              "$FF_SOURCE_DIR/toolkit/mozapps/installer/windows/nsis/common.nsh"

	cp "$REPO_ICON_DIR/windows/firefox.ico"            "$ff_branding_dir/firefox.ico"
	cp "$REPO_ICON_DIR/windows/VisualElements_70.png"  "$ff_branding_dir/VisualElements_70.png"
	cp "$REPO_ICON_DIR/windows/VisualElements_150.png" "$ff_branding_dir/VisualElements_150.png"
	cp "$REPO_ICON_DIR/windows/wizHeader.bmp"          "$ff_branding_dir/wizHeader.bmp"
	cp "$REPO_ICON_DIR/windows/wizHeaderRTL.bmp"       "$ff_branding_dir/wizHeaderRTL.bmp"
	cp "$REPO_ICON_DIR/windows/wizWatermark.bmp"       "$ff_branding_dir/wizWatermark.bmp"
fi


log "Patching version"

echo "MOZ_APP_VERSION='$SW_VERSION'" >> "$FF_SOURCE_DIR/browser/branding/sqlite-writer/configure.sh"
echo "$SW_VERSION" > "$FF_SOURCE_DIR/browser/config/version.txt"
echo "$SW_VERSION" > "$FF_SOURCE_DIR/browser/config/version_display.txt"


log "Patching installer"

# Ensure our additional files are included in the generated installer.

package_manifest="$FF_SOURCE_DIR/browser/installer/package-manifest.in"
echo '[sqlite-writer]'                          >> "$package_manifest"
if [[ "$BUILD_OS" = "linux" ]] ; then
	echo '@BINPATH@/sqlite-writer'          >> "$package_manifest"
	echo '@BINPATH@/sqlite-writer.desktop'  >> "$package_manifest"
fi
echo '@RESPATH@/apps/*'                           >> "$package_manifest"
echo '@RESPATH@/mozilla.cfg'                      >> "$package_manifest"
echo '@RESPATH@/defaults/pref/sqlite-writer.js' >> "$package_manifest"
sedi '/@BINPATH@\/@MOZ_APP_NAME@-bin/d'              "$package_manifest"

# Patch the duplicate file error caused by including the sqlite-manager
# extension in the installer.

allowed_dupes="$FF_SOURCE_DIR/browser/installer/allowed-dupes.mn"
echo 'apps/sqlite-manager/chrome/skin/default/images/close.gif'     >> "$allowed_dupes"
echo 'chrome/toolkit/skin/classic/global/icons/Close.gif'           >> "$allowed_dupes"
echo 'apps/sqlite-manager/chrome/icons/default/default16.png'       >> "$allowed_dupes"
echo 'apps/sqlite-manager/chrome/skin/default/images/default16.png' >> "$allowed_dupes"
echo 'apps/sqlite-manager/chrome/icons/default/default32.png'       >> "$allowed_dupes"
echo 'apps/sqlite-manager/chrome/skin/default/images/default32.png' >> "$allowed_dupes"

if [[ "$BUILD_OS" = "mac" ]] ; then
	# Replace Info.plist.in with our patched version, which includes:
	#  + Fixed executable name
	#  + Removed file/url associations
	cp "$REPO_CONFIG_DIR/Info.plist.in" "$FF_SOURCE_DIR/browser/app/macbuild/Contents/Info.plist.in"

	# Replace make_dmg.py with our patched version that takes care of the
	# code signing.
	cp "$REPO_CONFIG_DIR/make_dmg.py" "$FF_SOURCE_DIR/python/mozbuild/mozbuild/action/make_dmg.py"
fi

if [[ "$BUILD_OS" = "windows" ]] ; then
	# Copy over patched nsis files. The patches include:
	#  + Added shortcut in the installation directory 
	#  + Fixed branding
	#  + Fixed shortcuts (they need to start with parameters)
	#  + Removed file associations

	ff_nsis_dir="$FF_SOURCE_DIR/browser/installer/windows/nsis"
	cp "$REPO_NSIS_DIR/"* "$ff_nsis_dir"
fi


log "Patching 'Disabled Updater' bug"

if [[ "$BUILD_OS" = "mac" ]] ; then
	# When building Firefox 54.0.1 with the updater disabled on a Mac, the
	# build fails. This bug has been patched in later versions, and the fix
	# can be found here:
	# https://github.com/mozilla/gecko-dev/commit/5d98501bcf467c85def443ec6ad9c8b73a940cc3

	# The sed commands look funky because the sed that is bundled with Mac
	# is old, and "\n" is not supported within the replace string.

	guard_open='ifdef MOZ_UPDATER'
	guard_close='endif'

	sed -i '' "/mv -f/i\\
	  $guard_open\\
	  " "$FF_SOURCE_DIR/browser/app/Makefile.in"
	sed -i '' "/ln -s/a\\
	  $guard_close\\
	  " "$FF_SOURCE_DIR/browser/app/Makefile.in"

	guard_open='#ifdef MOZ_UPDATER'
	guard_close='#endif'

	sed -i '' "/LaunchServices/i\\
	  $guard_open\\
	  " "$FF_SOURCE_DIR/browser/installer/package-manifest.in"
	sed -i '' "/LaunchServices/a\\
	  $guard_close\\
	  " "$FF_SOURCE_DIR/browser/installer/package-manifest.in"
fi


log "Patching build flags"

cp "$REPO_CONFIG_DIR/mozconfig" "$FF_SOURCE_DIR/mozconfig"

if [[ "$BUILD_OS" = "mac" ]] ; then
	# 'com.teracet.sqlite writer' is not a valid bundle ID, so let's replace
	# the space with a dash.

	src_line='MOZ_MACBUNDLE_ID=`echo.*$'
	new_transform="tr '[A-Z]' '[a-z]' | tr ' ' '-'"
	new_line='MOZ_MACBUNDLE_ID=`echo $MOZ_APP_DISPLAYNAME | '$new_transform'`'
	sedi "s/$src_line/$new_line/" "$FF_SOURCE_DIR/old-configure.in"
fi


if [[ "$BUILD_OS" = "mac" ]] ; then
	log "Patching extra bundle indentifiers"

	old_id='org.mozilla.crashreporter'
	new_id='com.teracet.sqlite-writer.crashreporter'
	file="$FF_SOURCE_DIR/toolkit/crashreporter/client/macbuild/Contents/Info.plist"
	sedi "s/$old_id/$new_id/" "$file"

	old_id='org.mozilla.plugincontainer'
	new_id='com.teracet.sqlite-writer.plugincontainer'
	file="$FF_SOURCE_DIR/ipc/app/macbuild/Contents/Info.plist.in"
	sedi "s/$old_id/$new_id/" "$file"
fi

if [[ "$BUILD_OS" = "mac" ]] ; then
	log "Disabling private API usage disliked by Apple"

	# Disable CGSSetDebugOptions
	line='^\(.*CGSSetDebugOptions.*\)$'
	file="$FF_SOURCE_DIR/dom/plugins/ipc/PluginProcessChild.cpp"
	sedi "s/$line/\/\/\1/" "$file"
	file="$FF_SOURCE_DIR/widget/cocoa/nsAppShell.mm"
	sedi "s/$line/\/\/\1/" "$file"

	# Disable CGSSetWindowBackgroundBlurRadius
	line='^\(.*CGSSetWindowBackgroundBlurRadius.*\)$'
	file="$FF_SOURCE_DIR/widget/cocoa/nsCocoaWindow.mm"
	sedi "s/$line/\/\/\1/" "$file"

	# Disable NSTextInputReplacementRangeAttributeName
	line='^\(.*NSTextInputReplacementRangeAttributeName.*\)$'
	file="$FF_SOURCE_DIR/widget/cocoa/TextInputHandler.mm"
	sedi "s/$line/\/\/\1/" "$file"

	# Disable malloc_logger
	line='^\(.* malloc_logger.*\)$' # preceding space is intentional
	file="$FF_SOURCE_DIR/mozglue/misc/StackWalk.cpp"
	sedi "s/$line/\/\/\1/" "$file"
fi
