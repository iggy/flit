import 'package:flit/application/config/version_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/domain/models/update_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// About screen showing app version, gateway version, and update check
/// (ticket P9-08).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appVersionAsync = ref.watch(appVersionProvider);
    final gatewayStatus = ref.watch(gatewayStatusProvider);
    final updateCheckAsync = ref.watch(updateCheckProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App name
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: const Text('App Name'),
            subtitle: const Text('flit'),
          ),
          const Divider(),

          // App version
          appVersionAsync.when(
            data: (appVersion) => ListTile(
              leading: Icon(Icons.smartphone, color: theme.colorScheme.primary),
              title: const Text('App Version'),
              subtitle: Text(
                '${appVersion.version} (build ${appVersion.buildNumber})',
              ),
            ),
            loading: () => ListTile(
              leading: Icon(Icons.smartphone, color: theme.colorScheme.primary),
              title: const Text('App Version'),
              subtitle: const Text('Loading...'),
            ),
            error: (error, stack) => ListTile(
              leading: Icon(Icons.smartphone, color: theme.colorScheme.error),
              title: const Text('App Version'),
              subtitle: const Text('Unknown'),
            ),
          ),
          const Divider(),

          // Gateway version
          ListTile(
            leading: Icon(
              gatewayStatus != null ? Icons.cloud : Icons.cloud_off,
              color: gatewayStatus != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            title: const Text('Gateway Version'),
            subtitle: gatewayStatus != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gatewayStatus.version),
                      if (gatewayStatus.releaseDate != null)
                        Text(
                          'Released ${gatewayStatus.releaseDate}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  )
                : const Text('Not connected'),
          ),
          const Divider(),

          // Update check
          updateCheckAsync.when(
            data: (updateCheck) {
              final status = updateCheck.status;
              final statusColor = _statusColor(status, theme);
              final statusIcon = _statusIcon(status);
              final statusText = _statusText(updateCheck);

              return ListTile(
                leading: Icon(statusIcon, color: statusColor),
                title: const Text('Update Status'),
                subtitle: Text(statusText),
              );
            },
            loading: () => ListTile(
              leading: Icon(Icons.update, color: theme.colorScheme.primary),
              title: const Text('Update Status'),
              subtitle: const Text('Checking...'),
            ),
            error: (error, stack) => ListTile(
              leading: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              title: const Text('Update Status'),
              subtitle: const Text('Check failed'),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(UpdateCheckStatus status, ThemeData theme) {
    switch (status) {
      case UpdateCheckStatus.upToDate:
        return theme.colorScheme.primary;
      case UpdateCheckStatus.gatewayNewer:
        return theme.colorScheme.tertiary;
      case UpdateCheckStatus.clientNewer:
        return theme.colorScheme.secondary;
      case UpdateCheckStatus.unknown:
        return theme.colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  IconData _statusIcon(UpdateCheckStatus status) {
    switch (status) {
      case UpdateCheckStatus.upToDate:
        return Icons.check_circle;
      case UpdateCheckStatus.gatewayNewer:
        return Icons.arrow_upward;
      case UpdateCheckStatus.clientNewer:
        return Icons.arrow_downward;
      case UpdateCheckStatus.unknown:
        return Icons.help_outline;
    }
  }

  String _statusText(UpdateCheck check) {
    switch (check.status) {
      case UpdateCheckStatus.upToDate:
        return 'App version matches gateway (${check.localVersion})';
      case UpdateCheckStatus.gatewayNewer:
        return 'Gateway is newer (${check.gatewayVersion}) than app (${check.localVersion})';
      case UpdateCheckStatus.clientNewer:
        return 'App is newer (${check.localVersion}) than gateway (${check.gatewayVersion})';
      case UpdateCheckStatus.unknown:
        return 'Cannot determine (not connected or version missing)';
    }
  }
}
