// P9-03 acceptance: notifications screen renders enabled/disabled states
// and unsupported-platform state.

import 'package:flit/application/config/preferences_providers.dart';
import 'package:flit/application/notifications/notification_providers.dart';
import 'package:flit/core/platform/notifications.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:flit/presentation/settings/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required NotificationService service, required bool enabled}) {
  return ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(service),
      preferencesStoreProvider.overrideWithValue(
        PreferencesStore(InMemoryKeyValueStore()),
      ),
      notificationsEnabledProvider.overrideWith(() => _SeededNotifier(enabled)),
    ],
    child: const MaterialApp(home: NotificationsScreen()),
  );
}

/// Seeds the initial flag only. [NotificationsEnabledNotifier.setEnabled] is
/// deliberately NOT overridden: the permission-denied banner is driven by the
/// real "only enable when the platform granted permission" logic.
final class _SeededNotifier extends NotificationsEnabledNotifier {
  _SeededNotifier(this._initial);

  final bool _initial;

  @override
  bool build() {
    super.build();
    return _initial;
  }
}

/// In-memory [KeyValueStore] so the notifier never touches secure storage.
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

final class _FakeService implements NotificationService {
  _FakeService({this.isSupported = true, this.permissionGranted = true});

  @override
  final bool isSupported;

  final bool permissionGranted;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}

void main() {
  testWidgets('renders with switch enabled', (tester) async {
    await tester.pumpWidget(_wrap(service: _FakeService(), enabled: true));
    await tester.pumpAndSettle();

    expect(find.text('Enable notifications'), findsOneWidget);
    final switchWidget = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchWidget.value, isTrue);
  });

  testWidgets('renders with switch disabled', (tester) async {
    await tester.pumpWidget(_wrap(service: _FakeService(), enabled: false));
    await tester.pumpAndSettle();

    expect(find.text('Enable notifications'), findsOneWidget);
    final switchWidget = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchWidget.value, isFalse);
  });

  testWidgets('unsupported platform disables switch', (tester) async {
    await tester.pumpWidget(
      _wrap(service: _FakeService(isSupported: false), enabled: false),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Notifications are not supported on this platform'),
      findsOneWidget,
    );
    final switchWidget = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchWidget.onChanged, isNull);
  });

  testWidgets('shows permission denied banner', (tester) async {
    await tester.pumpWidget(
      _wrap(service: _FakeService(permissionGranted: false), enabled: false),
    );
    await tester.pumpAndSettle();

    // Tap the switch to enable.
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Notification permission was denied. To enable '
        'notifications, grant permission in system settings.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('dismisses permission denied banner', (tester) async {
    await tester.pumpWidget(
      _wrap(service: _FakeService(permissionGranted: false), enabled: false),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Notification permission was denied. To enable '
        'notifications, grant permission in system settings.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Notification permission was denied. To enable '
        'notifications, grant permission in system settings.',
      ),
      findsNothing,
    );
  });
}
