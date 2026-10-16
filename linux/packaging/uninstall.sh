#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.github.quiqueporta.don3txt"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

rm -f "$DATA_HOME/applications/$APP_ID.desktop" "$DATA_HOME/icons/hicolor/512x512/apps/$APP_ID.png"

update-desktop-database "$DATA_HOME/applications" 2>/dev/null || true
gtk-update-icon-cache -f -t "$DATA_HOME/icons/hicolor" 2>/dev/null || true

echo "don3txt removed from your applications menu. Delete this folder to remove the app itself."
