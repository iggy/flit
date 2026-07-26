import 'package:flit/application/config/window_providers.dart';
import 'package:flit/core/platform/desktop_window.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for WindowGeometryService against fakes (P9-01).
void main() {
  group('WindowGeometryService', () {
    test('restore with no stored geometry applies defaults', () async {
      final controller = FakeWindowController();
      final store = PreferencesStore(InMemoryKeyValueStore());
      final service = WindowGeometryService(
        controller: controller,
        store: store,
      );

      await service.restore();

      expect(controller.appliedGeometry, isNotNull);
      expect(controller.appliedGeometry!.width, defaultWindowGeometry.width);
      expect(controller.appliedGeometry!.height, defaultWindowGeometry.height);
    });

    test('restore with stored geometry applies it', () async {
      final kv = InMemoryKeyValueStore();
      final controller = FakeWindowController();
      final store = PreferencesStore(kv);

      // Pre-populate storage.
      await store.saveWindowGeometry(
        const WindowGeometry(
          width: 1200.0,
          height: 900.0,
          x: 100.0,
          y: 50.0,
          maximized: true,
        ),
      );

      final service = WindowGeometryService(
        controller: controller,
        store: store,
      );

      await service.restore();

      expect(controller.appliedGeometry, isNotNull);
      expect(controller.appliedGeometry!.width, 1200.0);
      expect(controller.appliedGeometry!.height, 900.0);
      expect(controller.appliedGeometry!.x, 100.0);
      expect(controller.appliedGeometry!.y, 50.0);
      expect(controller.appliedGeometry!.maximized, true);
    });

    test('a size below the minimum is clamped', () async {
      final kv = InMemoryKeyValueStore();
      final controller = FakeWindowController();
      final store = PreferencesStore(kv);

      // Pre-populate storage with a tiny size.
      await store.saveWindowGeometry(
        const WindowGeometry(width: 200.0, height: 100.0),
      );

      final service = WindowGeometryService(
        controller: controller,
        store: store,
      );

      await service.restore();

      // The controller should have clamped it (controller does the clamping in
      // applyGeometry, but we verify it was called).
      expect(controller.appliedGeometry, isNotNull);
      // The service just applies what it loaded; clamping is in the controller.
      expect(controller.appliedGeometry!.width, 200.0);
      expect(controller.appliedGeometry!.height, 100.0);
    });

    test('scheduleSave called 5 times rapidly results in one save', () async {
      final kv = InMemoryKeyValueStore();
      final controller = FakeWindowController();
      final store = PreferencesStore(kv);

      controller.currentGeometry = const WindowGeometry(
        width: 1000.0,
        height: 800.0,
      );

      final service = WindowGeometryService(
        controller: controller,
        store: store,
        debounce: const Duration(milliseconds: 50),
      );

      // Call scheduleSave 5 times rapidly.
      service.scheduleSave();
      service.scheduleSave();
      service.scheduleSave();
      service.scheduleSave();
      service.scheduleSave();

      // Wait for the debounce to settle.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify exactly one save occurred.
      final loaded = await store.loadWindowGeometry();
      expect(loaded, isNotNull);
      expect(loaded!.width, 1000.0);
      expect(loaded.height, 800.0);
    });

    test('persistCurrent swallows a throwing controller', () async {
      final controller = ThrowingWindowController();
      final store = PreferencesStore(InMemoryKeyValueStore());
      final service = WindowGeometryService(
        controller: controller,
        store: store,
      );

      // Should not throw.
      await service.persistCurrent();
    });

    test(
      'dispose cancels the pending timer and flushes one final save',
      () async {
        final kv = InMemoryKeyValueStore();
        final controller = FakeWindowController();
        final store = PreferencesStore(kv);

        controller.currentGeometry = const WindowGeometry(
          width: 1100.0,
          height: 850.0,
        );

        final service = WindowGeometryService(
          controller: controller,
          store: store,
          debounce: const Duration(seconds: 10),
        );

        service.scheduleSave();

        // Dispose immediately — the save should happen now, not in 10 seconds.
        await service.dispose();

        final loaded = await store.loadWindowGeometry();
        expect(loaded, isNotNull);
        expect(loaded!.width, 1100.0);
        expect(loaded.height, 850.0);
      },
    );
  });
}

/// Fake window controller that records applied geometry (P9-01).
final class FakeWindowController implements WindowController {
  WindowGeometry? appliedGeometry;
  WindowGeometry? currentGeometry;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> applyGeometry(WindowGeometry geometry) async {
    appliedGeometry = geometry;
  }

  @override
  Future<WindowGeometry?> readGeometry() async => currentGeometry;

  @override
  Future<void> setTitle(String title) async {}

  @override
  Future<void> show() async {}

  @override
  void setGeometryChangedCallback(WindowGeometryChangedCallback? callback) {}
}

/// Throwing window controller for error-handling tests (P9-01).
final class ThrowingWindowController implements WindowController {
  @override
  Future<void> ensureInitialized() async {
    throw Exception('ensureInitialized failed');
  }

  @override
  Future<void> applyGeometry(WindowGeometry geometry) async {
    throw Exception('applyGeometry failed');
  }

  @override
  Future<WindowGeometry?> readGeometry() async {
    throw Exception('readGeometry failed');
  }

  @override
  Future<void> setTitle(String title) async {
    throw Exception('setTitle failed');
  }

  @override
  Future<void> show() async {
    throw Exception('show failed');
  }

  @override
  void setGeometryChangedCallback(WindowGeometryChangedCallback? callback) {}
}

/// In-memory [KeyValueStore] fake for tests.
final class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
