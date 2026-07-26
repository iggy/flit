/// Desktop window management abstraction (P9-01).
///
/// Wraps window_manager for testability and safe no-op behavior on mobile/web.
/// The app must never import window_manager directly — everything goes through
/// [WindowController].
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flit/data/storage/preferences_store.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// Minimum window dimensions to ensure the app is usable.
const double _kMinWindowWidth = 480.0;
const double _kMinWindowHeight = 600.0;

/// Default window size when no geometry is stored.
const double _kDefaultWindowWidth = 1100.0;
const double _kDefaultWindowHeight = 800.0;

/// True on desktop platforms where window_manager is supported (Linux, macOS,
/// Windows), false elsewhere (Android, iOS, web).
bool get isDesktopPlatform {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}

/// Callback for window geometry change events (resize, move, maximize/restore).
typedef WindowGeometryChangedCallback = void Function();

/// Minimal abstraction over window_manager for desktop window control.
///
/// The real implementation delegates to package:window_manager; the no-op
/// variant is used on mobile and web where window management is N/A, and in
/// tests to avoid platform channel dependencies.
abstract interface class WindowController {
  /// Initialize the window manager — must be called before any other operation.
  /// On unsupported platforms (mobile, web) this is a no-op.
  Future<void> ensureInitialized();

  /// Apply the given window geometry (size, position, maximized state).
  /// Clamps the size to the minimum dimensions.
  Future<void> applyGeometry(WindowGeometry geometry);

  /// Read the current window geometry from the platform.
  /// Returns null on mobile/web or when the geometry cannot be determined.
  Future<WindowGeometry?> readGeometry();

  /// Set the window title.
  Future<void> setTitle(String title);

  /// Show the window (makes it visible on screen).
  Future<void> show();

  /// Register a callback invoked whenever the window geometry changes (resize,
  /// move, maximize, unmaximize). Only one callback is supported; a second
  /// registration replaces the first.
  void setGeometryChangedCallback(WindowGeometryChangedCallback? callback);
}

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

/// No-op window controller for mobile, web, and tests (P9-01).
final class NoopWindowController implements WindowController {
  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> applyGeometry(WindowGeometry geometry) async {}

  @override
  Future<WindowGeometry?> readGeometry() async => null;

  @override
  Future<void> setTitle(String title) async {}

  @override
  Future<void> show() async {}

  @override
  void setGeometryChangedCallback(WindowGeometryChangedCallback? callback) {}
}

/// Provides default window geometry when no stored value exists (P9-01).
WindowGeometry get defaultWindowGeometry {
  return const WindowGeometry(
    width: _kDefaultWindowWidth,
    height: _kDefaultWindowHeight,
  );
}
