# Hermes Flutter app

Cross-platform (mobile + desktop) client for the Hermes Agent gateway.
Design and protocol contract: see [`../docs/`](../docs/) (start at
`../docs/roadmap.md`).

## Toolchain (pinned, Phase 0 / P0-01)

- **Flutter 3.44.8** (stable channel, installed at `~/flutter`)
- **Dart 3.12.2** (bundled with Flutter)
- Targets enabled: android, ios, linux, macos, windows, web.
  - Linux desktop is the primary dev target (GTK + clang toolchain installed).
  - Android toolchain intentionally not installed yet (deferred, see roadmap).
- Linux build deps (apt): `clang cmake ninja-build libgtk-3-dev libsecret-1-dev xz-utils`

## Develop

```sh
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen (freezed/json/riverpod)
flutter analyze                                            # must stay clean
flutter test
flutter run -d linux
```

Dependency versions are **pinned exact** in `pubspec.yaml`; `pubspec.lock` is
committed. Bump deliberately, not via `pub upgrade`.

Note: `custom_lint`/`riverpod_lint` are intentionally omitted (no release
compatible with riverpod 3.3 / freezed 3.1 yet) — deviation from
`docs/reference/04-app-architecture.md`, recorded in `pubspec.yaml`.
