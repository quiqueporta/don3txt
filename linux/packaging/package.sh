#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>   (run from the repository root after 'flutter build linux --release')" >&2
  exit 1
fi

VERSION="$1"
APP_ID="com.github.quiqueporta.don3txt"
APPIMAGETOOL_VERSION="1.9.1"
RUNTIME_VERSION="20251108"

PACKAGING_DIR="linux/packaging"
BUNDLE_DIR="build/linux/x64/release/bundle"
WORK_DIR="build/linux/packaging"
DIST_DIR="build/linux/dist"
TOOLS_DIR="$WORK_DIR/tools"

download_tools() {
  mkdir -p "$TOOLS_DIR"

  if [ ! -f "$TOOLS_DIR/appimagetool-$APPIMAGETOOL_VERSION" ]; then
    curl -fsSL -o "$TOOLS_DIR/appimagetool-$APPIMAGETOOL_VERSION" \
      "https://github.com/AppImage/appimagetool/releases/download/$APPIMAGETOOL_VERSION/appimagetool-x86_64.AppImage"
    chmod +x "$TOOLS_DIR/appimagetool-$APPIMAGETOOL_VERSION"
  fi

  if [ ! -f "$TOOLS_DIR/runtime-$RUNTIME_VERSION" ]; then
    curl -fsSL -o "$TOOLS_DIR/runtime-$RUNTIME_VERSION" \
      "https://github.com/AppImage/type2-runtime/releases/download/$RUNTIME_VERSION/runtime-x86_64"
  fi
}

build_appimage() {
  local app_dir="$WORK_DIR/AppDir"

  rm -rf "$app_dir"
  mkdir -p "$app_dir"
  cp -r "$BUNDLE_DIR"/. "$app_dir/"
  cp "$PACKAGING_DIR/$APP_ID.desktop" "$PACKAGING_DIR/$APP_ID.png" "$app_dir/"
  cp "$PACKAGING_DIR/AppRun" "$app_dir/AppRun"
  ln -s "$APP_ID.png" "$app_dir/.DirIcon"

  # The AppImage of appimagetool needs FUSE to mount itself; extracting it instead lets it run on CI runners without FUSE.
  APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 "$TOOLS_DIR/appimagetool-$APPIMAGETOOL_VERSION" \
    --no-appstream \
    --runtime-file "$TOOLS_DIR/runtime-$RUNTIME_VERSION" \
    "$app_dir" "$DIST_DIR/don3txt-v$VERSION-x86_64.AppImage"
}

build_tarball() {
  local name="don3txt-v$VERSION-linux-x86_64"
  local tar_dir="$WORK_DIR/$name"

  rm -rf "$tar_dir"
  mkdir -p "$tar_dir"
  cp -r "$BUNDLE_DIR"/. "$tar_dir/"
  cp "$PACKAGING_DIR/$APP_ID.desktop" "$PACKAGING_DIR/$APP_ID.png" \
    "$PACKAGING_DIR/install.sh" "$PACKAGING_DIR/uninstall.sh" "$tar_dir/"

  tar -czf "$DIST_DIR/$name.tar.gz" -C "$WORK_DIR" "$name"
}

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

download_tools
build_appimage
build_tarball

ls -lh "$DIST_DIR"
