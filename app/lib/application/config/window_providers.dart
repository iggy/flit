/// Desktop window geometry management and persistence (P9-01).
///
/// The app calls [windowGeometryServiceProvider] to restore on launch and
/// persist on resize/move/maximize. The service debounces rapid geometry
/// changes so a resize drag doesn't hammer storage 60 times per second.
library;

import 'dart:async';

import 'package:flit/application/config/preferences_providers.dart';
import 'package:flit/core/platform/desktop_window.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the window controller (real on desktop, no-op elsewhere).
final windowControllerProvider = Provider<WindowController>((ref) {
  if (isDesktopPlatform) {
    return WindowManagerController();
  }
  return NoopWindowController();
});

/// Service that orchestrates restoring and persisting window geometry (P9-01).
///
/// Call [restore] once at app start (after ensureInitialized); call
/// [scheduleSave] on every resize/move/maximize event. The save is debounced
/// so rapid events coalesce into one write. [dispose] cancels the pending
/// timer and flushes one final save.
final class WindowGeometryService {
  WindowGeometryService({
    required this.controller,
    required this.store,
    this.debounce = const Duration(milliseconds: 500),
  });

  final WindowController controller;
  final PreferencesStore store;
  final Duration debounce;
  Timer? _saveTimer;

  /// Restore the window geometry from storage, or apply defaults if absent.
  Future<void> restore() async {
    final stored = await store.loadWindowGeometry();
    final geometry = stored ?? defaultWindowGeometry;
    await controller.applyGeometry(geometry);
  }

  /// Schedule a save of the current geometry. Rapid calls are debounced into
  /// one write.
  void scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(debounce, _persistCurrentNow);
  }

  /// Persist the current window geometry immediately. Never throws — a failure
  /// to persist geometry must not crash the app.
  Future<void> persistCurrent() async {
    try {
      final geometry = await controller.readGeometry();
      if (geometry != null) {
        await store.saveWindowGeometry(geometry);
      }
    } on Object {
      // Swallow errors: geometry persistence is not critical.
    }
  }

  /// Cancel the pending save timer and flush one final save (if needed).
  Future<void> dispose() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await persistCurrent();
  }

  void _persistCurrentNow() {
    _saveTimer = null;
    // Fire and forget — the app must not block on save.
    persistCurrent();
  }
}

/// Provider for the window geometry service (P9-01).
final windowGeometryServiceProvider = Provider<WindowGeometryService>((ref) {
  final controller = ref.watch(windowControllerProvider);
  final store = ref.watch(preferencesStoreProvider);
  final service = WindowGeometryService(controller: controller, store: store);
  ref.onDispose(() async {
    await service.dispose();
  });
  return service;
});
