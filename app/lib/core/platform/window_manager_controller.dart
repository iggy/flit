/// Real [WindowController] backed by package:window_manager (P9-01).
///
/// Lives in its own library so that web builds never compile window_manager:
/// desktop_window.dart picks this file only where dart:io is available, and
/// the web stub in window_manager_controller_web.dart otherwise.
// window_manager 0.6 moved the 0.5.x API (windowManager, WindowListener) to
// legacy.dart. Migrating to the native Window/WindowManager API is a follow-up.
// The legacy bridge is deprecated; silence those infos until that migration.
// ignore_for_file: deprecated_member_use
library;

import 'dart:ui' as ui;

import 'package:flit/core/platform/desktop_window.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:window_manager/legacy.dart';

/// Minimum window dimensions to ensure the app is usable.
const double _kMinWindowWidth = 480.0;
const double _kMinWindowHeight = 600.0;

/// Real window controller delegating to package:window_manager (P9-01).
final class WindowManagerController
    implements WindowController, WindowListener {
  WindowGeometryChangedCallback? _callback;

  @override
  Future<void> ensureInitialized() async {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(
      const ui.Size(_kMinWindowWidth, _kMinWindowHeight),
    );
    windowManager.addListener(this);
  }

  @override
  Future<void> applyGeometry(WindowGeometry geometry) async {
    // Clamp size to the minimum.
    final width = geometry.width < _kMinWindowWidth
        ? _kMinWindowWidth
        : geometry.width;
    final height = geometry.height < _kMinWindowHeight
        ? _kMinWindowHeight
        : geometry.height;

    await windowManager.setSize(ui.Size(width, height));

    if (geometry.x != null && geometry.y != null) {
      await windowManager.setPosition(ui.Offset(geometry.x!, geometry.y!));
    }

    if (geometry.maximized) {
      await windowManager.maximize();
    } else {
      await windowManager.unmaximize();
    }
  }

  @override
  Future<WindowGeometry?> readGeometry() async {
    try {
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();
      final maximized = await windowManager.isMaximized();

      return WindowGeometry(
        width: size.width,
        height: size.height,
        x: position.dx,
        y: position.dy,
        maximized: maximized,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> setTitle(String title) async {
    await windowManager.setTitle(title);
  }

  @override
  Future<void> show() async {
    await windowManager.show();
  }

  @override
  void setGeometryChangedCallback(WindowGeometryChangedCallback? callback) {
    _callback = callback;
  }

  @override
  void onWindowResize() {
    _callback?.call();
  }

  @override
  void onWindowMove() {
    _callback?.call();
  }

  @override
  void onWindowResized() {
    _callback?.call();
  }

  @override
  void onWindowMoved() {
    _callback?.call();
  }

  @override
  void onWindowMaximize() {
    _callback?.call();
  }

  @override
  void onWindowUnmaximize() {
    _callback?.call();
  }

  @override
  void onWindowBlur() {}

  @override
  void onWindowClose() {}

  @override
  void onWindowDocked() {}

  @override
  void onWindowEnterFullScreen() {}

  @override
  void onWindowEvent(String eventName) {}

  @override
  void onWindowFocus() {}

  @override
  void onWindowLeaveFullScreen() {}

  @override
  void onWindowMinimize() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowUndocked() {}
}
