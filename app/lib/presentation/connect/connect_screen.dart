import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hermes/application/connection/connect_controller.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';

/// Connect screen (ticket P0-07): gateway URL + session token entry,
/// `/api/status` probe, live connection-state chip, and a toast on
/// `gateway.ready`.
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(connectControllerProvider.notifier)
        .connect(
          url: _urlController.text.trim(),
          token: _tokenController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final connectState = ref.watch(connectControllerProvider);
    final connectionState = ref.watch(connectionStateProvider);

    // Prefill from the stored config once it loads.
    ref.listen(connectionConfigProvider, (previous, next) {
      if (next != null &&
          _urlController.text.isEmpty &&
          _tokenController.text.isEmpty) {
        _urlController.text = next.baseUrl;
        _tokenController.text = next.token ?? '';
      }
    });

    // Connected → toast the gateway version and head to chat (P0-07).
    ref.listen(connectControllerProvider, (previous, next) {
      if (next.phase == ConnectPhase.connected &&
          previous?.phase != ConnectPhase.connected) {
        final version = next.status?.version;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              version == null
                  ? 'Connected to Hermes'
                  : 'Connected to Hermes v$version',
            ),
          ),
        );
        context.go('/chat');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Hermes'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _ConnectionChip(state: connectionState)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Text(
                  'Point the app at a running Hermes gateway. '
                  'The URL and session token are shown when the gateway '
                  'starts.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _urlController,
                  enabled: !connectState.busy,
                  decoration: const InputDecoration(
                    labelText: 'Gateway URL',
                    hintText: 'https://gateway.example.com',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the gateway URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tokenController,
                  enabled: !connectState.busy,
                  decoration: const InputDecoration(
                    labelText: 'Session token',
                    prefixIcon: Icon(Icons.key),
                  ),
                  obscureText: true,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the session token';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: connectState.busy ? null : _connect,
                  icon: connectState.busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt),
                  label: Text(switch (connectState.phase) {
                    ConnectPhase.probing => 'Probing…',
                    ConnectPhase.connecting => 'Connecting…',
                    _ => 'Connect',
                  }),
                ),
                if (connectState.status != null) ...<Widget>[
                  const SizedBox(height: 16),
                  _StatusCard(state: connectState),
                ],
                if (connectState.phase == ConnectPhase.error) ...<Widget>[
                  const SizedBox(height: 16),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              connectState.errorMessage ?? 'Unknown error',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({required this.state});

  final AsyncValue<GatewayConnectionState> state;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (state.value) {
      GatewayConnectionState.connecting => ('Connecting', Icons.sync),
      GatewayConnectionState.ready => ('Connected', Icons.cloud_done),
      GatewayConnectionState.reconnecting => (
        'Reconnecting',
        Icons.sync_problem,
      ),
      _ => ('Offline', Icons.cloud_off),
    };
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final ConnectUiState state;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    if (status == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Gateway v${status.version}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'running: ${status.gatewayRunning} · '
              'state: ${status.gatewayState ?? 'unknown'} · '
              'auth: ${status.authRequired ? 'OAuth' : 'token'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
