# Desktop Packaging Scripts

Packaging scripts for flit desktop builds (ticket P9-08).

**Scope:** CI + desktop packaging scripts + in-app update check. Store submission (Play/App Store) and crash reporting SDKs are out of scope.

## Prerequisites

Each platform requires its own packaging tools:

### Linux (AppImage)

- **appimagetool** — downloads as an AppImage from [AppImageKit releases](https://github.com/AppImage/AppImageKit/releases)
  ```sh
  wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool-x86_64.AppImage
  sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
  ```

### macOS (DMG)

- **hdiutil** — built into macOS, no installation required

### Windows (MSI/ZIP)

- **WiX Toolset v3** (optional, for MSI creation) — download from [wixtoolset.org](https://wixtoolset.org/)
- Falls back to a ZIP archive if WiX is not installed

## Usage

Run from the `app/` directory or via `task`:

```sh
cd app

# Linux AppImage
task package-linux
# or: ./packaging/linux_appimage.sh

# macOS DMG
task package-macos
# or: ./packaging/macos_dmg.sh

# Windows MSI/ZIP
task package-windows
# or: powershell -File packaging/windows_msi.ps1

# Dispatch by host OS
task package
```

## Code Signing

**Code signing and notarization are out of scope for this ticket (P9-08).**

- **macOS:** Unsigned DMG; notarization is not performed
- **Windows:** Unsigned ZIP/MSI; Authenticode signing is not performed
- **Linux:** AppImage is unsigned

## Output

Packages are written to `build/<platform>/`:

- Linux: `build/linux/flit-x86_64.AppImage`
- macOS: `build/macos/flit.dmg`
- Windows: `build/windows/flit-windows-x64.zip`

## See Also

- `Taskfile.yaml` — build and packaging tasks
- `.github/workflows/ci.yaml` — CI pipeline
- `docs/phases/` — project tickets
