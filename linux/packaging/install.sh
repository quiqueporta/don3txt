#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.github.quiqueporta.don3txt"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
ICON_DIR="$DATA_HOME/icons/hicolor/512x512/apps"
DESKTOP_DIR="$DATA_HOME/applications"

mkdir -p "$ICON_DIR" "$DESKTOP_DIR"
cp "$APP_DIR/$APP_ID.png" "$ICON_DIR/"
sed "s|^Exec=.*|Exec=\"$APP_DIR/don3txt\"|" "$APP_DIR/$APP_ID.desktop" > "$DESKTOP_DIR/$APP_ID.desktop"

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
gtk-update-icon-cache -f -t "$DATA_HOME/icons/hicolor" 2>/dev/null || true

echo "don3txt added to your applications menu. It runs from $APP_DIR, so keep this folder where it is."
