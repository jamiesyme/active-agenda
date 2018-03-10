#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/apps/sqlite-manager"

# Update the .desktop file icon
ICON_PATH="$APP_DIR/icons/mozicon128.png"
sed -i -e "s|^Icon=$|Icon=$ICON_PATH|" "$ROOT_DIR/sqlite-writer.desktop"

# Launch the app
"$ROOT_DIR/sqlite-writer-bin" --app "$APP_DIR/application.ini"
