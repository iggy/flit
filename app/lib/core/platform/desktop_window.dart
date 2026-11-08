/// Desktop window management abstraction (P9-01).
///
/// Wraps window_manager for testability and safe no-op behavior on mobile/web.
/// The app must never import window_manager directly — everything goes through
/// [WindowController].
library;

import 'dart:async';

import 'package:flit/data/storage/preferences_store.dart';
import 'package:flutter/foundation.dart';

export 'window_manager_controller_web.dart'
    if (dart.library.io) 'window_manager_controller.dart';

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
