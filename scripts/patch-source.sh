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

ff_branding_dir="$FF_SOURCE_DIR/browser/branding/active-agenda"
cp -r "$FF_SOURCE_DIR/browser/branding/unofficial" "$ff_branding_dir"

# Use the firefox-branding.js file as our preferences file. It'd be preferable
# to keep the file elsewhere, but I was having trouble including it in the
# compiled omni.ja, so this will have to do.

#cp "$REPO_CONFIG_DIR/active-agenda.js" "$ff_branding_dir/pref/firefox-branding.js"

# Update any references to "Firefox" or "Mozilla", and overwrite branding
# images. Note that some windows installer files (.nsi) are patched in this
# section.

sedi -e 's/"Nightly"/"Active Agenda"/'     "$ff_branding_dir/locales/en-US/brand.dtd"
sedi -e 's/=Nightly/=Active Agenda/'       "$ff_branding_dir/locales/en-US/brand.properties"
sedi -e 's/"Mozilla"/"Teracet"/'           "$ff_branding_dir/locales/en-US/brand.dtd"
sedi -e 's/=Mozilla/=Teracet/'             "$ff_branding_dir/locales/en-US/brand.properties"
sedi -e 's/Nightly/"Active Agenda"/'       "$ff_branding_dir/configure.sh"
echo 'MOZ_APP_NAME="active-agenda-bin"' >> "$ff_branding_dir/configure.sh" # Is this only needed on Windows?

# -- Mac
#echo 'MOZ_MACBUNDLE_NAME="Active Agenda.app"' >> "$BRANDING_DIR/configure.sh" # Doesn't work
cp "$REPO_CONFIG_DIR/dsstore" "$ff_branding_dir/dsstore"
cp "$REPO_ICON_DIR/mac/background.png" "$ff_branding_dir/background.png"
cp "$REPO_ICON_DIR/mac/firefox.icns" "$ff_branding_dir/firefox.icns"

# -- Windows
sedi -e 's/"Mozilla Developer Preview"/"Active Agenda"/' "$ff_branding_dir/branding.nsi"
sedi -e 's/"mozilla.org"/"teracet.com"/'                 "$ff_branding_dir/branding.nsi"

ff_nsis_dir="$FF_SOURCE_DIR/browser/installer/windows/nsis"
sedi -e 's/Mozilla Firefox/Active Agenda/'                  "$ff_nsis_dir/../app.tag"
sedi -e 's/FirefoxMessageWindow/ActiveAgendaMessageWindow/' "$ff_nsis_dir/defines.nsi.in"
sedi -e 's/Firefox/Active Agenda/'                          "$ff_nsis_dir/defines.nsi.in"
sedi -e 's/\\Mozilla/\\Teracet/'                            "$FF_SOURCE_DIR/toolkit/mozapps/installer/windows/nsis/common.nsh"

cp "$REPO_ICON_DIR/windows/firefox.ico"            "$ff_branding_dir/firefox.ico"
cp "$REPO_ICON_DIR/windows/firefox.ico"            "$ff_branding_dir/firefox64.ico"
cp "$REPO_ICON_DIR/windows/VisualElements_70.png"  "$ff_branding_dir/VisualElements_70.png"
cp "$REPO_ICON_DIR/windows/VisualElements_150.png" "$ff_branding_dir/VisualElements_150.png"
cp "$REPO_ICON_DIR/windows/wizHeader.bmp"          "$ff_branding_dir/wizHeader.bmp"
cp "$REPO_ICON_DIR/windows/wizHeaderRTL.bmp"       "$ff_branding_dir/wizHeaderRTL.bmp"
cp "$REPO_ICON_DIR/windows/wizWatermark.bmp"       "$ff_branding_dir/wizWatermark.bmp"

# -- Linux
cp "$REPO_ICON_DIR/icon_16x16.png"   "$ff_branding_dir/default16.png"
cp "$REPO_ICON_DIR/icon_32x32.png"   "$ff_branding_dir/default32.png"
cp "$REPO_ICON_DIR/icon_48x48.png"   "$ff_branding_dir/default48.png"
cp "$REPO_ICON_DIR/icon_48x48.png"   "$ff_branding_dir/content/icon48.png"
cp "$REPO_ICON_DIR/icon_64x64.png"   "$ff_branding_dir/default64.png"
cp "$REPO_ICON_DIR/icon_64x64.png"   "$ff_branding_dir/content/icon64.png"
cp "$REPO_ICON_DIR/icon_128x128.png" "$ff_branding_dir/default128.png"
cp "$REPO_ICON_DIR/icon_128x128.png" "$ff_branding_dir/mozicon128.png"


log "Patching version"

echo "MOZ_APP_VERSION='$AA_VERSION'" >> "$FF_SOURCE_DIR/browser/branding/active-agenda/configure.sh"
echo "$AA_VERSION" > "$FF_SOURCE_DIR/browser/config/version.txt"
echo "$AA_VERSION" > "$FF_SOURCE_DIR/browser/config/version_display.txt"


log "Patching installer"

# Ensure our additional files are included in the generated installer.

package_manifest="$FF_SOURCE_DIR/browser/installer/package-manifest.in"
echo '[active-agenda]'                          >> "$package_manifest"
if [[ "$BUILD_OS" = "linux" ]] ; then
	echo '@BINPATH@/active-agenda'          >> "$package_manifest"
	echo '@BINPATH@/active-agenda.desktop'  >> "$package_manifest"
fi
echo '@RESPATH@/active-agenda.cfg'              >> "$package_manifest"
echo '@RESPATH@/browser/aaupdater/*'            >> "$package_manifest"
echo '@RESPATH@/browser/application.ini'        >> "$package_manifest"
echo '@RESPATH@/defaults/pref/active-agenda.js' >> "$package_manifest"
sedi -e '/@BINPATH@\/@MOZ_APP_NAME@-bin/d'         "$package_manifest"

# Some files have to be inserted JUST before packaging, so we need to add a hook
# to allow for that.

package_mk_path="$FF_SOURCE_DIR/toolkit/mozapps/installer/packager.mk"
script_path="$REPO_SCRIPTS_DIR/patch-staged-package.sh"
old_cmd="\\\$(MAKE_PACKAGE)"
new_cmd="$script_path '\\\$(MOZ_PKG_DIR)' \\&\\& \\\$(MAKE_PACKAGE)"
sedi -e "s|$old_cmd|$new_cmd|" "$package_mk_path"

# Patch a duplicate file error caused by mysterious chrome.manifest.

#allowed_dupes="$FF_SOURCE_DIR/browser/installer/allowed-dupes.mn"
#echo 'browser/chrome/chrome.manifest' >> "$allowed_dupes"
#echo 'removed-files'                  >> "$allowed_dupes"

# Patch the duplicate file error caused by including the sqlite-manager
# extension in the installer.
# DISABLED

#allowed_dupes="$FF_SOURCE_DIR/browser/installer/allowed-dupes.mn"
#echo 'apps/sqlite-manager/chrome/skin/default/images/close.gif'     >> "$allowed_dupes"
#echo 'chrome/toolkit/skin/classic/global/icons/Close.gif'           >> "$allowed_dupes"
#echo 'apps/sqlite-manager/chrome/icons/default/default16.png'       >> "$allowed_dupes"
#echo 'apps/sqlite-manager/chrome/skin/default/images/default16.png' >> "$allowed_dupes"
#echo 'apps/sqlite-manager/chrome/icons/default/default32.png'       >> "$allowed_dupes"
#echo 'apps/sqlite-manager/chrome/skin/default/images/default32.png' >> "$allowed_dupes"

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


log "Patching build flags"

cp "$REPO_CONFIG_DIR/mozconfig" "$FF_SOURCE_DIR/mozconfig"

log "Disabling built-in addons"

sedi -Ee 's/\{"system":.+\}/\{"system":\[\]\}/' "$FF_SOURCE_DIR/browser/app/Makefile.in"

if [[ "$BUILD_OS" = "mac" ]] ; then
	# 'com.teracet.active agenda' is not a valid bundle ID, so let's replace
	# the space with a dash.

	src_line='MOZ_MACBUNDLE_ID=`echo.*$'
	new_transform="tr '[A-Z]' '[a-z]' | tr ' ' '-'"
	new_line='MOZ_MACBUNDLE_ID=`echo $MOZ_APP_DISPLAYNAME | '$new_transform'`'
	sedi -e "s/$src_line/$new_line/" "$FF_SOURCE_DIR/old-configure.in"
fi


if [[ "$BUILD_OS" = "mac" ]] ; then
	log "Patching extra bundle indentifiers"

	old_id='org.mozilla.crashreporter'
	new_id='com.teracet.active-agenda.crashreporter'
	file="$FF_SOURCE_DIR/toolkit/crashreporter/client/macbuild/Contents/Info.plist"
	sedi -e "s/$old_id/$new_id/" "$file"

	old_id='org.mozilla.plugincontainer'
	new_id='com.teracet.active-agenda.plugincontainer'
	file="$FF_SOURCE_DIR/ipc/app/macbuild/Contents/Info.plist.in"
	sedi -e "s/$old_id/$new_id/" "$file"
fi

if [[ "$BUILD_OS" = "mac" ]] ; then
	log "Disabling private API usage disliked by Apple"

	# Disable CGSSetDebugOptions
	line='^\(.*CGSSetDebugOptions.*\)$'
	file="$FF_SOURCE_DIR/dom/plugins/ipc/PluginProcessChild.cpp"
	sedi -e "s/$line/\/\/\1/" "$file"
	file="$FF_SOURCE_DIR/widget/cocoa/nsAppShell.mm"
	sedi -e "s/$line/\/\/\1/" "$file"

	# Disable CGSSetWindowBackgroundBlurRadius
	line='^\(.*CGSSetWindowBackgroundBlurRadius.*\)$'
	file="$FF_SOURCE_DIR/widget/cocoa/nsCocoaWindow.mm"
	sedi -e "s/$line/\/\/\1/" "$file"

	# Disable NSTextInputReplacementRangeAttributeName
	line='^\(.*NSTextInputReplacementRangeAttributeName.*\)$'
	file="$FF_SOURCE_DIR/widget/cocoa/TextInputHandler.mm"
	sedi -e "s/$line/\/\/\1/" "$file"
fi
