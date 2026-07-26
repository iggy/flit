import 'package:flit/application/connection/connect_controller.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/router/pending_deep_link_provider.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/auth_provider.dart';
import 'package:flit/presentation/common/connection_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Connect screen (ticket P0-07; gated user/pass added post-MVP).
///
/// Two-step flow (docs/reference/01-gateway-protocol.md §2):
/// 1. Enter the gateway URL → **Continue** probes `/api/status` (+ the auth
///    providers on a gated gateway).
/// 2. Loopback → session-token field; gated → provider picker +
///    username/password (cookies minted on login, WS via single-use ticket).
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedProvider;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _probe() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(connectControllerProvider.notifier)
        .probe(url: _urlController.text.trim());
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final controller = ref.read(connectControllerProvider.notifier);
    final mode = ref.read(connectControllerProvider).authMode;
    switch (mode) {
      case AuthMode.token:
        await controller.connectToken(
          url: _urlController.text.trim(),
          token: _tokenController.text.trim(),
        );
      case AuthMode.password:
        await controller.connectPassword(
          url: _urlController.text.trim(),
          provider: _selectedProvider ?? '',
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      case AuthMode.oauth:
        await controller.connectOAuth(
          url: _urlController.text.trim(),
          provider: _selectedProvider ?? '',
        );
      case null:
        break; // Not probed yet.
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectState = ref.watch(connectControllerProvider);
    final connectionState = ref.watch(connectionStateProvider).value;

    // Prefill from the stored config once it loads; a stored GATED config
    // with live cookies gets one automatic reconnect attempt (the 30-day
    // refresh cookie usually still holds — protocol §2.2).
    ref.listen(connectionConfigProvider, (previous, next) {
      if (next != null && _urlController.text.isEmpty) {
        _urlController.text = next.baseUrl;
        _tokenController.text = next.token ?? '';
        _usernameController.text = next.username ?? '';
        _selectedProvider = next.authProvider;
        if ((next.authMode == AuthMode.password ||
                next.authMode == AuthMode.oauth) &&
            ref.read(connectControllerProvider).phase == ConnectPhase.idle) {
          Future<void>.microtask(
            () => ref.read(connectControllerProvider.notifier).connectStored(),
          );
        }
      }
    });

    // Connected → toast the gateway version and head to chat (P0-07).
    // Ticket P9-02: honor a pending deep link instead of always going to /chat.
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
        // Check for a pending deep link; fall back to /chat.
        final pending = ref
            .read(pendingDeepLinkProvider.notifier)
            .consumePending();
        context.go(pending ?? '/chat');
      }
    });

    // Default the provider selection once the list arrives.
    final providers = connectState.providers;
    if (_selectedProvider == null &&
        providers != null &&
        providers.isNotEmpty) {
      _selectedProvider = providers.first.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Hermes'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: ConnectionChip(state: connectionState)),
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
                  'Point the app at a running Hermes gateway.',
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
                  onFieldSubmitted: (_) => _probe(),
                ),
                const SizedBox(height: 16),
                // The probe button lives until an auth mode is detected
                // (idle, probing, and pre-probe errors all keep it so the
                // user can retry).
                if (connectState.authMode == null)
                  FilledButton.icon(
                    onPressed: connectState.busy ? null : _probe,
                    icon: connectState.phase == ConnectPhase.probing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      connectState.phase == ConnectPhase.probing
                          ? 'Probing…'
                          : 'Continue',
                    ),
                  ),
                if (connectState.authMode == AuthMode.token &&
                    !connectState.busy) ...<Widget>[
                  TextFormField(
                    controller: _tokenController,
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
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.bolt),
                    label: const Text('Connect'),
                  ),
                ],
                if (connectState.authMode == AuthMode.oauth &&
                    !connectState.busy) ...<Widget>[
                  if (providers != null && providers.isNotEmpty) ...<Widget>[
                    Text(
                      'Sign in with OAuth',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    for (final AuthProviderInfo provider in providers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FilledButton.icon(
                          onPressed: () {
                            _selectedProvider = provider.name;
                            _submit();
                          },
                          icon: const Icon(Icons.login),
                          label: Text(
                            'Sign in with ${provider.displayName.isEmpty ? provider.name : provider.displayName}',
                          ),
                        ),
                      ),
                  ],
                ],
                if (connectState.authMode == AuthMode.password &&
                    !connectState.busy) ...<Widget>[
                  if (providers != null && providers.length > 1)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProvider,
                      decoration: const InputDecoration(
                        labelText: 'Sign-in provider',
                        prefixIcon: Icon(Icons.account_circle_outlined),
                      ),
                      items: <DropdownMenuItem<String>>[
                        for (final AuthProviderInfo p in providers)
                          DropdownMenuItem<String>(
                            value: p.name,
                            child: Text(
                              p.displayName.isEmpty ? p.name : p.displayName,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedProvider = value),
                    ),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    autocorrect: false,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                ],
                if (connectState.busy &&
                    connectState.phase == ConnectPhase.connecting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
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
              'auth: ${status.authRequired ? 'gated' : 'token'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
