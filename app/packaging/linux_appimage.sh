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
Name=Flit
Comment=Flutter client for Hermes Agent gateway
Exec=flit
Icon=flit
Type=Application
Categories=Utility;Development;
Terminal=false
EOF

# Install the app icons into the hicolor theme. Sources are generated from the
# master artwork by packaging/generate_app_icons.py and shipped in the bundle.
ICON_SRC_DIR="$BUNDLE_DIR/data/resources"
for size in 16 32 48 64 128 256 512; do
  icon="$ICON_SRC_DIR/flit_${size}.png"
  if [[ ! -f "$icon" ]]; then
    echo "Error: missing app icon $icon"
    echo "       Run: python3 packaging/generate_app_icons.py"
    exit 1
  fi
  dest="$APPDIR/usr/share/icons/hicolor/${size}x${size}/apps"
  mkdir -p "$dest"
  install -m 644 "$icon" "$dest/flit.png"
done

# appimagetool expects the .desktop file's icon next to AppRun. It must be a
# real file, not a symlink into usr/ (some appimagetool builds reject those).
install -m 644 "$ICON_SRC_DIR/flit_256.png" "$APPDIR/flit.png"

echo "==> Checking for appimagetool..."
if ! command -v appimagetool &> /dev/null; then
  echo "appimagetool not found; downloading the AppImage release into build/tools/..."
  mkdir -p build/tools
  wget -q -O build/tools/appimagetool \
    https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x build/tools/appimagetool
  export PATH="$(pwd)/build/tools:$PATH"
  if ! command -v appimagetool &> /dev/null; then
    echo "ERROR: failed to obtain appimagetool." >&2
    exit 1
  fi
fi

echo "==> Building AppImage..."
appimagetool "$APPDIR" "build/linux/flit-x86_64.AppImage"

echo ""
echo "==> AppImage built successfully: build/linux/flit-x86_64.AppImage"
