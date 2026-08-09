#!/usr/bin/env bash
# Linux .deb / .rpm packaging script for flit (ticket P9-08).
#
# Stages the Flutter linux release bundle into standard FHS layout and
# produces both a .deb (Debian/Ubuntu) and a .rpm (Fedora/RHEL/openSUSE).
#
# Prerequisites:
#   - A successful `flutter build linux --release` (the bundle is reused).
#   - `dpkg-deb` (comes with dpkg, present on Debian/Ubuntu runners).
#   - `rpmbuild` (install the `rpm` package on Ubuntu runners).
#
# Output: build/linux/flit-<version>.deb and build/linux/flit-<version>.rpm

set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="flit"
VERSION=$(grep -E '^version:' pubspec.yaml | head -n1 | awk '{print $2}' | cut -d+ -f1)
BUNDLE_DIR="build/linux/x64/release/bundle"
STAGE="build/linux/pkg-staging"
OUT_DIR="build/linux"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "Error: bundle not found at $BUNDLE_DIR. Run 'flutter build linux --release' first." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Common staging: FHS layout used by both package formats.
# ---------------------------------------------------------------------------
rm -rf "$STAGE"
mkdir -p "$STAGE/usr/bin" "$STAGE/usr/lib/$APP_NAME" "$STAGE/usr/share/applications" \
         "$STAGE/usr/share/icons/hicolor" "$STAGE/usr/share/doc/$APP_NAME"
mkdir "$STAGE/DEBIAN"
chmod 755 "$STAGE/DEBIAN"

# Binary + runtime libs + assets go into the app's private lib dir.
cp "$BUNDLE_DIR/$APP_NAME" "$STAGE/usr/lib/$APP_NAME/"
cp -r "$BUNDLE_DIR/lib" "$STAGE/usr/lib/$APP_NAME/"
cp -r "$BUNDLE_DIR/data" "$STAGE/usr/lib/$APP_NAME/"

# launcher
cat > "$STAGE/usr/bin/$APP_NAME" <<EOF
#!/bin/sh
export LD_LIBRARY_PATH="/usr/lib/$APP_NAME/lib:\${LD_LIBRARY_PATH}"
exec "/usr/lib/$APP_NAME/$APP_NAME" "\$@"
EOF
chmod 755 "$STAGE/usr/bin/$APP_NAME"

# desktop entry
cat > "$STAGE/usr/share/applications/$APP_NAME.desktop" <<'EOF'
[Desktop Entry]
Name=Flit
Comment=Flutter client for Hermes Agent gateway
Exec=flit
Icon=flit
Type=Application
Categories=Utility;Development;
Terminal=false
EOF

# hicolor icons
ICON_SRC="$BUNDLE_DIR/data/resources"
for size in 16 32 48 64 128 256 512; do
  if [[ -f "$ICON_SRC/flit_${size}.png" ]]; then
    dest="$STAGE/usr/share/icons/hicolor/${size}x${size}/apps"
    mkdir -p "$dest"
    install -m 644 "$ICON_SRC/flit_${size}.png" "$dest/flit.png"
  fi
done

# license
LICENSE="$(dirname "$0")/../../LICENSE"
if [[ -f "$LICENSE" ]]; then
  install -m 644 "$LICENSE" "$STAGE/usr/share/doc/$APP_NAME/copyright"
else
  echo "WARNING: LICENSE not found; skipping copyright file." >&2
fi

# ---------------------------------------------------------------------------
# DEB
# ---------------------------------------------------------------------------
cat > "$STAGE/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Iggy Jackson <iggy@kws1.com>
Description: Flutter client for the Hermes Agent gateway
 Cross-platform gateway client for Hermes Agent. Thin client that connects
 to a running gateway over WebSocket JSON-RPC.
EOF

dpkg-deb --build --root-owner-group "$STAGE" "$OUT_DIR/${APP_NAME}_${VERSION}_amd64.deb" >/dev/null

# ---------------------------------------------------------------------------
# RPM
# ---------------------------------------------------------------------------
if ! command -v rpmbuild &> /dev/null; then
  echo "Warning: rpmbuild not found; skipping RPM (install the 'rpm' package)." >&2
else
  RPM_ROOT="build/linux/rpmbuild"
  rm -rf "$RPM_ROOT"
  mkdir -p "$RPM_ROOT"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

  # The staged FHS tree is copied verbatim into the buildroot by %install.
  STAGE_ABS="$(cd "$STAGE" && pwd)"

  cat > "$RPM_ROOT/SPECS/$APP_NAME.spec" <<EOF
Name: $APP_NAME
Version: $VERSION
Release: 1
Summary: Flutter client for the Hermes Agent gateway
License: MIT
BuildArch: x86_64

%description
Cross-platform gateway client for Hermes Agent. Thin client that connects
to a running gateway over WebSocket JSON-RPC.

%prep
%build
%install
rm -rf %{buildroot}
cp -r $STAGE_ABS/. %{buildroot}/
chmod -R u+w %{buildroot}

%clean
rm -rf %{buildroot}

%files
/usr/bin/$APP_NAME
/usr/lib/$APP_NAME
/usr/share/applications/$APP_NAME.desktop
/usr/share/icons/hicolor
/usr/share/doc/$APP_NAME
EOF

  rpmbuild --define "_topdir $PWD/$RPM_ROOT" -bb "$PWD/$RPM_ROOT/SPECS/$APP_NAME.spec" >/dev/null 2>&1 \
    && cp "$RPM_ROOT"/RPMS/x86_64/*.rpm "$OUT_DIR/${APP_NAME}-${VERSION}-1.x86_64.rpm" \
    || echo "Warning: rpmbuild failed; check the SPEC and buildroot layout." >&2
fi

echo ""
echo "==> Packages written to $OUT_DIR/:"
ls -la "$OUT_DIR"/*.deb "$OUT_DIR"/*.rpm 2>/dev/null || true
