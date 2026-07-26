#!/usr/bin/env bash
# Linux AppImage packaging script for flit (ticket P9-08).
#
# Builds the Flutter linux release, assembles an AppDir, and invokes
# appimagetool to produce a distributable AppImage.
#
# Prerequisites: appimagetool must be on PATH.
# Code signing and notarization are out of scope.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Building Flutter linux release..."
flutter build linux --release

BUNDLE_DIR="build/linux/x64/release/bundle"
APPDIR="build/linux/AppDir"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "Error: Bundle directory not found at $BUNDLE_DIR"
  exit 1
fi

echo "==> Assembling AppDir..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy the bundle
cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/bin/"

# Create AppRun
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/flit" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Create .desktop file
cat > "$APPDIR/flit.desktop" <<'EOF'
[Desktop Entry]
Name=flit
Comment=Flutter client for Hermes Agent gateway
Exec=flit
Icon=flit
Type=Application
Categories=Utility;Development;
Terminal=false
EOF

# Create a placeholder icon (256x256 transparent PNG)
# In a real setup, replace this with the actual app icon
cat > "$APPDIR/usr/share/icons/hicolor/256x256/apps/flit.png" <<'EOF_ICON'
iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA
GXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAADhJREFUeNrs0DEBAAAAwqD1T20M
H6AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHwGBBgAEc4AAcc0JgIAAAAASUVORK5C
YII=
EOF_ICON
chmod 644 "$APPDIR/usr/share/icons/hicolor/256x256/apps/flit.png"

# Symlink icon to AppDir root
ln -sf "usr/share/icons/hicolor/256x256/apps/flit.png" "$APPDIR/flit.png"

echo "==> Checking for appimagetool..."
if ! command -v appimagetool &> /dev/null; then
  echo ""
  echo "ERROR: appimagetool is not installed or not on PATH."
  echo ""
  echo "To install appimagetool:"
  echo "  1. Download from https://github.com/AppImage/AppImageKit/releases"
  echo "  2. Make it executable: chmod +x appimagetool-x86_64.AppImage"
  echo "  3. Move to PATH: sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool"
  echo ""
  exit 1
fi

echo "==> Building AppImage..."
appimagetool "$APPDIR" "build/linux/flit-x86_64.AppImage"

echo ""
echo "==> AppImage built successfully: build/linux/flit-x86_64.AppImage"
