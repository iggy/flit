/// Notification providers (ticket P9-03).
///
/// Wires the [NotificationService] abstraction to preferences persistence and
/// subscribes to gateway events (`background.complete`) and pending approval
/// prompts to post local notifications.
library;

import 'dart:async';

import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/config/preferences_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/notifications/notification_format.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/platform/notifications.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification service singleton. Override in tests with [NoopNotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

/// Notifications enabled flag (ticket P9-03).
///
/// Persisted via [preferencesStoreProvider]. Default false. When enabling,
/// the service is initialized and permission is requested — the flag is only
/// set true if permission was granted.
final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
      NotificationsEnabledNotifier.new,
    );

class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future<void>.microtask(_loadStored);
    return false;
  }

  Future<void> _loadStored() async {
    final stored = await ref
        .read(preferencesStoreProvider)
        .loadNotificationsEnabled();
    if (!state) {
      state = stored;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      final service = ref.read(notificationServiceProvider);
      await service.initialize();
      final granted = await service.requestPermission();
      state = granted;
      await ref
          .read(preferencesStoreProvider)
          .saveNotificationsEnabled(granted);
    } else {
      state = false;
      await ref.read(preferencesStoreProvider).saveNotificationsEnabled(false);
    }
  }
}

/// Notification bridge state (ticket P9-03).
///
/// Tracks the set of already-notified keys so nothing double-fires, and
/// counts the number of notifications posted (for testing/debugging).
final class NotificationBridgeState {
  const NotificationBridgeState({
    this.notifiedKeys = const <String>{},
    this.count = 0,
  });

  final Set<String> notifiedKeys;
  final int count;

  @override
  bool operator ==(Object other) {
    return other is NotificationBridgeState &&
        other.notifiedKeys.length == notifiedKeys.length &&
        other.notifiedKeys.containsAll(notifiedKeys) &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(notifiedKeys), count);

  @override
  String toString() =>
      'NotificationBridgeState(notifiedKeys: $notifiedKeys, count: $count)';
}

/// The notification bridge (ticket P9-03).
///
/// Subscribes to:
/// - [gatewayEventsProvider]: posts a notification on `background.complete`.
/// - [messageListProvider]: posts a notification when a NEW [ApprovalPrompt]
///   appears, and cancels it when the prompt disappears.
///
/// Does NOTHING when [notificationsEnabledProvider] is false. The bridge is
/// self-contained: watching [notificationBridgeProvider] activates it.
final notificationBridgeProvider =
    NotifierProvider<NotificationBridge, NotificationBridgeState>(
      NotificationBridge.new,
    );

class NotificationBridge extends Notifier<NotificationBridgeState> {
  ProviderSubscription<AsyncValue<GatewayEvent>>? _eventsSubscription;
  String? _lastActiveSessionId;

  @override
  NotificationBridgeState build() {
    // Watch the flag; when it goes false, cancel everything.
    final enabled = ref.watch(notificationsEnabledProvider);
    if (!enabled) {
      _cancelSubscriptions();
      return const NotificationBridgeState();
    }

    // Subscribe to gateway events for background.complete.
    _eventsSubscription = ref.listen(gatewayEventsProvider, (previous, next) {
      _handleGatewayEvent(next);
    });

    // Watch the active session id to track approval prompts. fireImmediately:
    // a session is usually ALREADY active when notifications get enabled, and
    // a plain listen only fires on change — the prompts of the current session
    // would never be watched.
    ref.listen(activeSessionProvider, fireImmediately: true, (previous, next) {
      _handleSessionChange(previous?.liveId, next.liveId);
    });

    ref.onDispose(_cancelSubscriptions);
    return const NotificationBridgeState();
  }

  void _cancelSubscriptions() {
    _eventsSubscription?.close();
    _eventsSubscription = null;
    _lastActiveSessionId = null;
  }

  void _handleGatewayEvent(AsyncValue<GatewayEvent> asyncEvent) {
    final raw = asyncEvent.value;
    if (raw == null) {
      return;
    }
    final event = parseGatewayEvent(raw);
    if (event is BackgroundCompleteEvent) {
      _notifyBackgroundComplete(event);
    }
  }

  void _notifyBackgroundComplete(BackgroundCompleteEvent event) {
    final key = 'background:${event.taskId}';
    if (state.notifiedKeys.contains(key)) {
      return;
    }
    final service = ref.read(notificationServiceProvider);
    final id = notificationIdFor(key);
    final body = notificationBody(event.text);
    service.show(id: id, title: 'Background task finished', body: body);
    state = NotificationBridgeState(
      notifiedKeys: <String>{...state.notifiedKeys, key},
      count: state.count + 1,
    );
  }

  void _handleSessionChange(String? previousSessionId, String? newSessionId) {
    if (previousSessionId != null && previousSessionId != newSessionId) {
      // Session changed: stop watching the old session's prompts.
      _lastActiveSessionId = null;
    }
    if (newSessionId == null) {
      return;
    }
    if (_lastActiveSessionId == newSessionId) {
      // Already watching this session.
      return;
    }
    _lastActiveSessionId = newSessionId;
    // Subscribe to the new session's message list for approval prompts.
    ref.listen(messageListProvider(newSessionId), (previous, next) {
      _handlePromptChange(previous?.pendingPrompts, next.pendingPrompts);
    });
  }

  void _handlePromptChange(
    List<InteractivePrompt>? previous,
    List<InteractivePrompt> current,
  ) {
    final previousApprovals =
        previous?.whereType<ApprovalPrompt>().toSet() ?? <ApprovalPrompt>{};
    final currentApprovals = current.whereType<ApprovalPrompt>().toSet();

    // Notify for NEW approvals (present in current, absent in previous).
    for (final approval in currentApprovals) {
      if (!previousApprovals.contains(approval)) {
        _notifyApproval(approval);
      }
    }

    // Cancel notifications for CLEARED approvals (present in previous, absent in current).
    for (final approval in previousApprovals) {
      if (!currentApprovals.contains(approval)) {
        _cancelApproval(approval);
      }
    }
  }

  void _notifyApproval(ApprovalPrompt approval) {
    final key = 'approval:${approval.sessionId}:${approval.command}';
    if (state.notifiedKeys.contains(key)) {
      return;
    }
    final service = ref.read(notificationServiceProvider);
    final id = notificationIdFor(key);
    final body = notificationBody(
      approval.description.isNotEmpty ? approval.description : approval.command,
    );
    service.show(id: id, title: 'Approval needed', body: body);
    state = NotificationBridgeState(
      notifiedKeys: <String>{...state.notifiedKeys, key},
      count: state.count + 1,
    );
  }

  void _cancelApproval(ApprovalPrompt approval) {
    final key = 'approval:${approval.sessionId}:${approval.command}';
    final service = ref.read(notificationServiceProvider);
    final id = notificationIdFor(key);
    service.cancel(id);
    // Remove the key from notifiedKeys so it can be re-notified if it reappears.
    final updatedKeys = Set<String>.from(state.notifiedKeys)..remove(key);
    state = NotificationBridgeState(
      notifiedKeys: updatedKeys,
      count: state.count,
    );
  }
}
