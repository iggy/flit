#!/usr/bin/env bash
# macOS DMG packaging script for flit (ticket P9-08).
#
# Builds the Flutter macOS release and creates a DMG disk image.
#
# Prerequisites: macOS with hdiutil (standard system tool).
# Code signing and notarization are out of scope.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Building Flutter macOS release..."
flutter build macos --release

APP_BUNDLE="build/macos/Build/Products/Release/flit.app"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Error: App bundle not found at $APP_BUNDLE"
  exit 1
fi

echo "==> Creating DMG..."
OUTPUT_DMG="build/macos/flit.dmg"
rm -f "$OUTPUT_DMG"

# Create a temporary directory for the DMG contents
TMP_DMG_DIR="build/macos/dmg_contents"
rm -rf "$TMP_DMG_DIR"
mkdir -p "$TMP_DMG_DIR"

# Copy the app bundle to the temp directory
cp -R "$APP_BUNDLE" "$TMP_DMG_DIR/"

# Create the DMG from the temp directory
hdiutil create -volname "flit" \
  -srcfolder "$TMP_DMG_DIR" \
  -ov -format UDZO \
  "$OUTPUT_DMG"

# Clean up temp directory
rm -rf "$TMP_DMG_DIR"

echo ""
echo "==> DMG created successfully: $OUTPUT_DMG"
echo ""
echo "NOTE: This DMG is unsigned. Code signing and notarization are out of scope."
