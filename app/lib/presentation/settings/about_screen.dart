import 'package:flit/application/config/version_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/desktop_contract.dart';
import 'package:flit/domain/models/desktop_contract.dart';
import 'package:flit/domain/models/gateway_status.dart';
import 'package:flit/domain/models/update_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key of the app-bar action that re-probes `/api/status`.
const Key aboutRefreshStatusKey = Key('about_refresh_status');

/// Key of the desktop-contract row (shown once a session has reported one).
const Key aboutDesktopContractKey = Key('about_desktop_contract');

/// About screen showing app version, gateway version, and update check
/// (ticket P9-08), plus the gateway's own housekeeping readout from
/// `/api/status` — config schema version, update availability, restart-drain
/// state, and search-index rebuild progress (gateway 0.20).
///
/// Everything in the gateway section is informational and every field is
/// nullable: a pre-0.20 gateway omits all of it and the rows simply don't
/// render. The status here is the connect-time probe, so the refresh action
/// re-probes rather than leaving a stale rebuild percent on screen.
class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  bool _refreshing = false;

  Future<void> _refreshStatus() async {
    if (_refreshing) {
      return;
    }
    setState(() => _refreshing = true);
    final ok = await ref.read(gatewayStatusProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    setState(() => _refreshing = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach the gateway to refresh.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appVersionAsync = ref.watch(appVersionProvider);
    final gatewayStatus = ref.watch(gatewayStatusProvider);
    final updateCheckAsync = ref.watch(updateCheckProvider);
    final contract = ref.watch(desktopContractProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        actions: <Widget>[
          IconButton(
            key: aboutRefreshStatusKey,
            tooltip: 'Refresh gateway status',
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: gatewayStatus == null ? null : _refreshStatus,
          ),
        ],
      ),
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

          ..._contractRows(theme, contract),

          if (gatewayStatus != null) ..._gatewaySection(theme, gatewayStatus),
        ],
      ),
    );
  }

  /// Desktop-contract version (optional-doc §3). Unlike everything else here
  /// this comes from the session bootstrap rather than `/api/status`, so it is
  /// unknown until a session exists — and unknown renders nothing, because
  /// "not told" is not the same as "old".
  List<Widget> _contractRows(ThemeData theme, DesktopContract contract) {
    final version = contract.version;
    if (version == null) {
      return const <Widget>[];
    }
    final behind = contract.isBehind;
    return <Widget>[
      const Divider(),
      ListTile(
        key: aboutDesktopContractKey,
        leading: Icon(
          behind ? Icons.warning_amber : Icons.handshake_outlined,
          color: behind
              ? theme.colorScheme.tertiary
              : theme.colorScheme.primary,
        ),
        title: const Text('Client Contract'),
        subtitle: Text(
          behind
              // Host-side remedy again: flit can't update the gateway.
              ? 'This gateway speaks v$version; flit expects '
                    'v${DesktopContract.minimum}. Update your Hermes gateway — '
                    'large attachments will fail until you do.'
              : 'v$version',
        ),
      ),
    ];
  }

  /// The gateway's own housekeeping readout. Each row appears only when the
  /// gateway actually sent the field, so a pre-0.20 gateway shows none of it
  /// and the section header is suppressed with them.
  List<Widget> _gatewaySection(ThemeData theme, GatewayStatus status) {
    final rows = <Widget>[
      ..._configVersionRows(theme, status),
      ..._updateAvailabilityRows(theme, status),
      ..._drainRows(theme, status),
      ..._rebuildRows(theme, status),
      ..._topologyRows(theme, status),
    ];
    if (rows.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      const Divider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          'Gateway host',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      ...rows,
    ];
  }

  List<Widget> _configVersionRows(ThemeData theme, GatewayStatus status) {
    final current = status.configVersion;
    final latest = status.latestConfigVersion;
    if (current == null || latest == null) {
      return const <Widget>[];
    }
    final needsMigration = status.configMigrationNeeded;
    return <Widget>[
      ListTile(
        leading: Icon(
          needsMigration ? Icons.upgrade : Icons.description_outlined,
          color: needsMigration
              ? theme.colorScheme.tertiary
              : theme.colorScheme.primary,
        ),
        title: const Text('Config Schema'),
        subtitle: Text(
          needsMigration
              // The migration is a host-side CLI action; flit has no RPC for
              // it, so name the command instead of offering a dead button.
              ? 'Version $current, this gateway ships $latest — '
                    'run `hermes config migrate` on the host'
              : 'Version $current (current)',
        ),
      ),
    ];
  }

  List<Widget> _updateAvailabilityRows(ThemeData theme, GatewayStatus status) {
    final canUpdate = status.canUpdateHermes;
    if (canUpdate == null) {
      return const <Widget>[];
    }
    return <Widget>[
      ListTile(
        leading: Icon(
          canUpdate ? Icons.system_update_alt : Icons.lock_outline,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: const Text('Host Updates'),
        subtitle: Text(
          canUpdate
              ? 'This host can run `hermes update` itself'
              : 'Managed externally — the container or launcher updates Hermes',
        ),
      ),
    ];
  }

  List<Widget> _drainRows(ThemeData theme, GatewayStatus status) {
    final drainable = status.gatewayDrainable;
    if (drainable == null) {
      return const <Widget>[];
    }
    final timeout = status.restartDrainTimeout;
    return <Widget>[
      ListTile(
        leading: Icon(
          drainable
              ? Icons.pause_circle_outline
              : Icons.do_not_disturb_on_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: const Text('Restart Drain'),
        subtitle: Text(
          <String>[
            drainable
                ? 'Ready to drain for a restart'
                : 'Not drainable right now (already draining or down)',
            if (timeout != null)
              'waits up to ${_formatSeconds(timeout)} for running turns',
          ].join(' · '),
        ),
      ),
    ];
  }

  List<Widget> _rebuildRows(ThemeData theme, GatewayStatus status) {
    final rebuild = status.ftsRebuild;
    if (rebuild == null) {
      // Absent means no rebuild pending — the healthy case, nothing to say.
      return const <Widget>[];
    }
    return <Widget>[
      ListTile(
        leading: Icon(Icons.manage_search, color: theme.colorScheme.tertiary),
        title: const Text('Search Index'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Rebuilding — ${rebuild.percent}% '
              '(${rebuild.indexed} of ${rebuild.total} messages). '
              'Searching older messages is slower and incomplete until it '
              'finishes.',
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: rebuild.fraction),
          ],
        ),
      ),
    ];
  }

  List<Widget> _topologyRows(ThemeData theme, GatewayStatus status) {
    final mode = status.gatewayMode;
    final profiles = status.profiles;
    if (mode == null && (profiles == null || profiles.isEmpty)) {
      return const <Widget>[];
    }
    final live = status.liveGatewayProfiles;
    return <Widget>[
      ListTile(
        leading: Icon(
          Icons.account_tree_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        title: const Text('Profiles & Gateways'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (mode != null) Text(_gatewayModeLabel(mode)),
            if (profiles != null && profiles.isNotEmpty)
              Text(
                profiles
                    .map((name) => live.contains(name) ? '$name (live)' : name)
                    .join(', '),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    ];
  }

  /// `gateway_mode` in words (`web_server.py` `_collect_profile_gateway_topology`).
  String _gatewayModeLabel(String mode) {
    switch (mode) {
      case 'multiplex':
        return 'One gateway serving several profiles';
      case 'single':
        return 'One gateway running';
      case 'multiple':
        return 'Separate gateway per profile';
      case 'none':
        return 'No gateway process running';
      default:
        return 'Topology unknown';
    }
  }

  /// Drain timeout for humans: the wire sends a float number of seconds.
  String _formatSeconds(double seconds) {
    if (seconds >= 60 && seconds % 60 == 0) {
      final minutes = seconds ~/ 60;
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    }
    final rounded = seconds == seconds.roundToDouble()
        ? seconds.toStringAsFixed(0)
        : seconds.toStringAsFixed(1);
    return '${rounded}s';
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
