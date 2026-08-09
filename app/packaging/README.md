# Desktop Packaging Scripts

Packaging scripts for flit desktop builds (ticket P9-08).

**Scope:** CI + desktop packaging scripts + in-app update check. Store submission (Play/App Store) and crash reporting SDKs are out of scope.

## App icons

Every platform's launcher icon is generated from the master artwork at the repo
root (`icon.png`) by `generate_app_icons.py`. The generated assets are committed,
so this only needs re-running when the artwork changes:

```sh
cd app
python3 packaging/generate_app_icons.py            # needs Pillow + numpy
python3 packaging/generate_app_icons.py --preview   # writes a contact sheet to /tmp
```

It writes, from one source image:

| Platform | Output |
| --- | --- |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — 15 sizes, opaque (no alpha, per App Store rules) |
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` — 7 sizes, rounded with transparent margin (macOS does not mask icons) |
| Android | `mipmap-*/ic_launcher.png` (legacy) + `mipmap-*/ic_launcher_foreground.png` (adaptive) |
| Web | `web/favicon.png`, `web/icons/Icon-{192,512}.png`, `Icon-maskable-{192,512}.png` |
| Windows | `windows/runner/resources/app_icon.ico` — 7 sizes in one .ico |
| Linux | `linux/runner/resources/flit_{16..512}.png` |

Notes on the non-obvious parts:

- The master artwork is a rounded badge on a white canvas. Platforms that apply
  their own corner mask get a **full-bleed** version, with the badge's gradient
  extrapolated into the corners — shipping the rounded artwork as-is would leave
  white nubs at the corners once iOS/Android round it again.
- Android adaptive foregrounds inset the badge into the guaranteed-visible
  central 66/108dp, so no launcher mask clips the "FLIT" wordmark. The backdrop
  colour is duplicated in `res/values/ic_launcher_background.xml`; the script
  prints the sampled value, so update that file if the artwork's gradient
  changes.
- Linux has no icon slot in the Flutter template. The PNGs are installed into
  the bundle at `data/resources/` by `linux/CMakeLists.txt`; the runner loads
  them into the window (`my_application.cc`) and `linux_appimage.sh` copies them
  into the AppDir's hicolor theme for the desktop entry.

## Prerequisites

Each platform requires its own packaging tools:

### Linux (AppImage)

- **appimagetool** — downloads as an AppImage from [AppImageKit releases](https://github.com/AppImage/AppImageKit/releases)
  ```sh
  wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x appimagetool-x86_64.AppImage
  sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
  ```
  Only needed for `package-linux`. The raw executable bundle (`package-linux-binary`) has no prerequisites.

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

# Linux raw executable (self-contained bundle, no AppImage)
task package-linux-binary
# or: ./packaging/linux_binary.sh

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

- Linux: `build/linux/flit-x86_64.AppImage` (AppImage), or `build/linux/flit-linux-x64/` (raw executable bundle)
- macOS: `build/macos/flit.dmg`
- Windows: `build/windows/flit-windows-x64.zip`

## See Also

- `Taskfile.yaml` — build and packaging tasks
- `.github/workflows/ci.yaml` — CI pipeline
- `docs/phases/` — project tickets
