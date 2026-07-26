/// Notifications settings screen (ticket P9-03).
///
/// Exposes a toggle for local notifications (background.complete, pending
/// approvals). Requests platform permission when enabling; shows a dismissible
/// banner when permission was denied.
library;

import 'package:flit/application/notifications/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _permissionDenied = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(notificationServiceProvider);
    final enabled = ref.watch(notificationsEnabledProvider);
    final isSupported = service.isSupported;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Column(
        children: <Widget>[
          if (_permissionDenied)
            Material(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Notification permission was denied. To enable '
                        'notifications, grant permission in system settings.',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      onPressed: () => setState(() {
                        _permissionDenied = false;
                      }),
                    ),
                  ],
                ),
              ),
            ),
          SwitchListTile(
            title: const Text('Enable notifications'),
            subtitle: Text(
              isSupported
                  ? 'Notify for background task completions and approvals needing attention'
                  : 'Notifications are not supported on this platform',
            ),
            value: enabled,
            onChanged: isSupported ? _toggle : null,
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(bool value) async {
    await ref.read(notificationsEnabledProvider.notifier).setEnabled(value);
    final actuallyEnabled = ref.read(notificationsEnabledProvider);
    if (value && !actuallyEnabled) {
      // User wanted to enable, but permission was denied.
      setState(() {
        _permissionDenied = true;
      });
    }
  }
}
