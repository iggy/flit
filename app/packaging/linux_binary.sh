#!/usr/bin/env bash
# Linux raw binary packaging script for flit.
#
# Flutter's `flutter build linux` already produces a self-contained bundle:
# the `flit` executable plus its shared libraries in `lib/` and its assets in
# `data/`. This script stages that bundle into build/linux/flit-linux-x64/ so
# it can be shipped as-is (no AppImage tooling required).
#
# Prerequisites: none beyond a successful `flutter build linux`.

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Building Flutter linux release..."
flutter build linux --release

BUNDLE_DIR="build/linux/x64/release/bundle"
STAGE_DIR="build/linux/flit-linux-x64"

if [[ ! -d "$BUNDLE_DIR" ]]; then
  echo "Error: Bundle directory not found at $BUNDLE_DIR"
  exit 1
fi

echo "==> Staging executable bundle..."
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp -r "$BUNDLE_DIR"/* "$STAGE_DIR/"

echo ""
echo "==> Bundle staged: $STAGE_DIR"
echo "    Run it with: $STAGE_DIR/flit"
