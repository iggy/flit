/// Notification service abstraction (ticket P9-03).
///
/// A thin, testable layer over `flutter_local_notifications` so nothing above
/// imports the plugin directly. Supports cross-platform local notifications
/// with explicit permission flows.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Platform-agnostic notification service interface.
abstract interface class NotificationService {
  /// Initialize the notification system. Must be called before [show].
  Future<void> initialize();

  /// Request notification permission from the OS.
  ///
  /// Returns true if permission was granted, false otherwise. Some platforms
  /// (Android <13) auto-grant; iOS/macOS/Android 13+ show a permission prompt.
  Future<bool> requestPermission();

  /// Show a notification with the given [id], [title], and [body].
  ///
  /// The [id] is used for cancellation and update tracking. Safe to call even
  /// when the platform doesn't support notifications — silently no-ops.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });

  /// Cancel a previously shown or scheduled notification by [id].
  Future<void> cancel(int id);

  /// True when this platform supports local notifications.
  bool get isSupported;
}

/// Real notification service backed by flutter_local_notifications.
///
/// Wraps ALL plugin calls so platform failures never throw out of this class
/// — notifications are best-effort. Respects platform-specific permission
/// flows (ticket P9-03: "respect platform permission flows").
final class LocalNotificationService implements NotificationService {
  LocalNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isWindows;
  }

  @override
  Future<void> initialize() async {
    if (_initialized || !isSupported) {
      return;
    }
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      // iOS/macOS: requestAlertPermission=false means permissions are NOT
      // implicitly requested at init — they must be requested explicitly via
      // requestPermission() (the "respect platform permission flows" requirement).
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'Flit',
        appUserModelId: 'com.hermes.flit',
        guid: '00000000-0000-0000-0000-000000000000',
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } on Object {
      // Best-effort: a failing init means notifications won't work, but the
      // app must not crash.
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!isSupported || !_initialized) {
      return false;
    }
    try {
      if (Platform.isAndroid) {
        // Android 13+ needs POST_NOTIFICATIONS runtime permission.
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImpl != null) {
          final granted = await androidImpl.requestNotificationsPermission();
          return granted ?? false;
        }
        // Android <13 auto-grants; no explicit request needed.
        return true;
      } else if (Platform.isIOS) {
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      } else if (Platform.isMacOS) {
        final macosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final granted = await macosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      // Linux/Windows: no explicit permission required.
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!isSupported || !_initialized) {
      return;
    }
    try {
      // Android notification channel setup.
      const androidDetails = AndroidNotificationDetails(
        'flit_alerts',
        'Flit Alerts',
        channelDescription: 'Notifications for background tasks and approvals',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const linuxDetails = LinuxNotificationDetails();
      const windowsDetails = WindowsNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
        linux: linuxDetails,
        windows: windowsDetails,
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } on Object {
      // Best-effort: a failing show must not crash the app.
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!isSupported || !_initialized) {
      return;
    }
    try {
      await _plugin.cancel(id: id);
    } on Object {
      // Best-effort: ignore cancellation failures.
    }
  }
}

/// No-op notification service for tests and unsupported platforms.
final class NoopNotificationService implements NotificationService {
  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}
