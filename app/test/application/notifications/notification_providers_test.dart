// P9-03 acceptance: the notification bridge posts notifications for
// background.complete and approval prompts, respects the enabled flag,
// and never double-fires.

import 'dart:async';

import 'package:flit/application/chat/message_fold.dart';
import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/config/preferences_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/notifications/notification_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/platform/notifications.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory key-value store for tests (from connection_store_test.dart).
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

/// Fake notification service that records show/cancel calls.
final class FakeNotificationService implements NotificationService {
  final List<ShowCall> showCalls = <ShowCall>[];
  final List<int> cancelCalls = <int>[];
  bool permissionGranted = true;

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    showCalls.add(ShowCall(id: id, title: title, body: body));
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls.add(id);
  }
}

final class ShowCall {
  const ShowCall({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;

  @override
  String toString() => 'ShowCall(id: $id, title: $title, body: $body)';

  @override
  bool operator ==(Object other) {
    return other is ShowCall &&
        other.id == id &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode => Object.hash(id, title, body);
}

/// Stream controller for fake gateway events.
StreamController<GatewayEvent> _eventsController() {
  return StreamController<GatewayEvent>.broadcast();
}

ProviderContainer _container({
  required FakeNotificationService service,
  required StreamController<GatewayEvent> eventsController,
  bool notificationsEnabled = true,
  String? activeSessionId,
}) {
  final kv = InMemoryKeyValueStore();
  return ProviderContainer(
    overrides: [
      notificationServiceProvider.overrideWithValue(service),
      preferencesStoreProvider.overrideWithValue(PreferencesStore(kv)),
      notificationsEnabledProvider.overrideWith(
        () => _FakeNotificationsEnabledNotifier(notificationsEnabled),
      ),
      gatewayEventsProvider.overrideWith((ref) {
        return eventsController.stream.asyncMap((event) async => event);
      }),
      messageListProvider.overrideWith2(_FakeMessageListNotifier.new),
      if (activeSessionId != null)
        activeSessionProvider.overrideWith(
          () => _FakeActiveSessionNotifier(activeSessionId),
        ),
    ],
  );
}

/// Fake active session notifier that starts with a given session id.
final class _FakeActiveSessionNotifier extends ActiveSessionNotifier {
  _FakeActiveSessionNotifier(this._liveId);

  final String _liveId;

  @override
  ActiveSessionState build() => ActiveSessionState(liveId: _liveId);
}

/// Fake notifier that starts with the given enabled state.
final class _FakeNotificationsEnabledNotifier
    extends NotificationsEnabledNotifier {
  _FakeNotificationsEnabledNotifier(this._initial);

  final bool _initial;

  @override
  bool build() => _initial;

  @override
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
  }
}

/// Fake message list notifier that can be driven via setPrompts.
final class _FakeMessageListNotifier extends MessageListNotifier {
  _FakeMessageListNotifier(super.liveId);

  @override
  FoldState build() => const FoldState();

  void setPrompts(List<InteractivePrompt> prompts) {
    state = state.copyWith(pendingPrompts: prompts);
  }
}

void main() {
  group('NotificationsEnabledNotifier', () {
    test('setEnabled(true) with granted permission sets state true', () async {
      final service = FakeNotificationService();
      final container = ProviderContainer(
        overrides: [
          notificationServiceProvider.overrideWithValue(service),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(notificationsEnabledProvider.notifier)
          .setEnabled(true);

      expect(container.read(notificationsEnabledProvider), isTrue);
    });

    test(
      'setEnabled(true) with denied permission leaves state false',
      () async {
        final service = FakeNotificationService()..permissionGranted = false;
        final container = ProviderContainer(
          overrides: [
            notificationServiceProvider.overrideWithValue(service),
            preferencesStoreProvider.overrideWithValue(
              PreferencesStore(InMemoryKeyValueStore()),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(notificationsEnabledProvider.notifier)
            .setEnabled(true);

        expect(container.read(notificationsEnabledProvider), isFalse);
      },
    );
  });

  group('NotificationBridge', () {
    test('disabled → no notification on background.complete', () async {
      final service = FakeNotificationService();
      final eventsController = _eventsController();
      final container = _container(
        service: service,
        eventsController: eventsController,
        notificationsEnabled: false,
      );
      addTearDown(container.dispose);
      addTearDown(eventsController.close);

      // Hold a listener: a bare read would let the auto-dispose bridge (and its
      // event subscriptions) be torn down immediately.
      container.listen(notificationBridgeProvider, (_, _) {});

      eventsController.add(
        GatewayEvent(
          type: 'background.complete',
          sessionId: 'sess1',
          payload: <String, dynamic>{
            'task_id': 'task123',
            'text': 'Task finished successfully',
          },
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.showCalls, isEmpty);
    });

    test('enabled → posts notification on background.complete', () async {
      final service = FakeNotificationService();
      final eventsController = _eventsController();
      final container = _container(
        service: service,
        eventsController: eventsController,
        notificationsEnabled: true,
      );
      addTearDown(container.dispose);
      addTearDown(eventsController.close);

      // Hold a listener: a bare read would let the auto-dispose bridge (and its
      // event subscriptions) be torn down immediately.
      container.listen(notificationBridgeProvider, (_, _) {});
      // Allow the listen subscriptions to set up.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      eventsController.add(
        GatewayEvent(
          type: 'background.complete',
          sessionId: 'sess1',
          payload: <String, dynamic>{
            'task_id': 'task123',
            'text': 'Task finished successfully',
          },
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(service.showCalls.length, 1);
      expect(service.showCalls[0].title, 'Background task finished');
      expect(service.showCalls[0].body, 'Task finished successfully');
    });

    test(
      'same background.complete twice posts only ONE notification',
      () async {
        final service = FakeNotificationService();
        final eventsController = _eventsController();
        final container = _container(
          service: service,
          eventsController: eventsController,
          notificationsEnabled: true,
        );
        addTearDown(container.dispose);
        addTearDown(eventsController.close);

        container.listen(notificationBridgeProvider, (_, _) {});
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final event = GatewayEvent(
          type: 'background.complete',
          sessionId: 'sess1',
          payload: <String, dynamic>{
            'task_id': 'task123',
            'text': 'Task finished successfully',
          },
        );
        eventsController.add(event);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        eventsController.add(event);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(service.showCalls.length, 1);
      },
    );

    test('new approval prompt posts notification', () async {
      final service = FakeNotificationService();
      final eventsController = _eventsController();
      final container = _container(
        service: service,
        eventsController: eventsController,
        notificationsEnabled: true,
        activeSessionId: 'sess1',
      );
      addTearDown(container.dispose);
      addTearDown(eventsController.close);

      // Hold a listener: a bare read would let the auto-dispose bridge (and its
      // event subscriptions) be torn down immediately.
      container.listen(notificationBridgeProvider, (_, _) {});

      // Add an approval prompt.
      final approval = ApprovalPrompt(
        sessionId: 'sess1',
        command: 'rm -rf build',
        description: 'Delete build directory',
      );
      final notifier =
          container.read(messageListProvider('sess1').notifier)
              as _FakeMessageListNotifier;
      notifier.setPrompts(<InteractivePrompt>[approval]);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.showCalls.length, 1);
      expect(service.showCalls[0].title, 'Approval needed');
      expect(service.showCalls[0].body, 'Delete build directory');
    });

    test('cleared approval prompt cancels notification', () async {
      final service = FakeNotificationService();
      final eventsController = _eventsController();
      final container = _container(
        service: service,
        eventsController: eventsController,
        notificationsEnabled: true,
        activeSessionId: 'sess1',
      );
      addTearDown(container.dispose);
      addTearDown(eventsController.close);

      container.listen(notificationBridgeProvider, (_, _) {});

      final approval = ApprovalPrompt(
        sessionId: 'sess1',
        command: 'rm -rf build',
        description: 'Delete build directory',
      );
      final notifier =
          container.read(messageListProvider('sess1').notifier)
              as _FakeMessageListNotifier;
      notifier.setPrompts(<InteractivePrompt>[approval]);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.showCalls.length, 1);

      // Clear the prompt.
      notifier.setPrompts(<InteractivePrompt>[]);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.cancelCalls.length, 1);
    });
  });
}
