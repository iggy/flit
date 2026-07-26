/// Provider API key management (ticket P4-01): save/disconnect provider
/// credentials. Lists providers with auth state badges (reusing the pattern
/// from [ModelPickerSheet]); unauthenticated api_key providers show an "Add
/// key" dialog with an obscured TextField; authenticated providers show
/// "Disconnect".
library;

import 'dart:async';

import 'package:flit/application/models/model_providers.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderKeysScreen extends ConsumerWidget {
  const ProviderKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(modelOptionsProvider);
    final keyState = ref.watch(providerKeyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Keys')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (keyState.busy) const LinearProgressIndicator(),
          if (keyState.error != null) _ErrorBanner(message: keyState.error!),
          Expanded(
            child: switch (optionsAsync) {
              AsyncData(:final value) => _buildProviderList(
                context,
                ref,
                providers: value.providers,
                busy: keyState.busy,
              ),
              AsyncError(:final error) => _PaneMessage(
                icon: Icons.error_outline,
                text: 'Could not load providers: $error',
              ),
              _ => const _PaneMessage(icon: null, text: 'Loading providers…'),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList(
    BuildContext context,
    WidgetRef ref, {
    required List<ModelProvider> providers,
    required bool busy,
  }) {
    if (providers.isEmpty) {
      return const _PaneMessage(
        icon: Icons.cloud_off,
        text: 'No providers available.',
      );
    }

    return ListView(
      children: providers.map((provider) {
        return _buildProviderTile(context, ref, provider: provider, busy: busy);
      }).toList(),
    );
  }

  Widget _buildProviderTile(
    BuildContext context,
    WidgetRef ref, {
    required ModelProvider provider,
    required bool busy,
  }) {
    final theme = Theme.of(context);
    final authenticated = provider.authenticated;
    final needsKey =
        !authenticated &&
        (provider.authType == 'api_key' ||
            (provider.authType == null && provider.keyEnv != null));

    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(provider.name, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: 8),
          if (authenticated)
            _Badge(
              label: 'Authenticated',
              icon: Icons.verified_user_outlined,
              theme: theme,
            )
          else if (needsKey)
            _Badge(
              label: 'Needs key',
              icon: Icons.key_off_outlined,
              theme: theme,
              warning: true,
            ),
        ],
      ),
      subtitle: provider.keyEnv != null
          ? Text('Key: ${provider.keyEnv}')
          : null,
      trailing: authenticated
          ? TextButton.icon(
              icon: const Icon(Icons.link_off, size: 16),
              label: const Text('Disconnect'),
              onPressed: busy
                  ? null
                  : () => unawaited(
                      _showDisconnectDialog(context, ref, provider),
                    ),
            )
          : (needsKey
                ? TextButton.icon(
                    icon: const Icon(Icons.key, size: 16),
                    label: const Text('Add key'),
                    onPressed: busy
                        ? null
                        : () => unawaited(
                            _showAddKeyDialog(context, ref, provider),
                          ),
                  )
                : null),
    );
  }

  Future<void> _showAddKeyDialog(
    BuildContext context,
    WidgetRef ref,
    ModelProvider provider,
  ) {
    final keyController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.key),
        title: Text('Add API key for ${provider.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (provider.keyEnv != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Enter your ${provider.keyEnv} API key:',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'API key',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final key = keyController.text.trim();
              if (key.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                unawaited(
                  ref
                      .read(providerKeyControllerProvider.notifier)
                      .saveKey(provider.slug, key),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDisconnectDialog(
    BuildContext context,
    WidgetRef ref,
    ModelProvider provider,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_outlined),
        title: Text('Disconnect ${provider.name}?'),
        content: const Text(
          'This will remove the saved credentials for this provider.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(
                ref
                    .read(providerKeyControllerProvider.notifier)
                    .disconnect(provider.slug),
              );
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

/// A small pill for auth state badges.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.theme,
    this.icon,
    this.warning = false,
  });

  final String label;
  final ThemeData theme;
  final IconData? icon;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final background = warning
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = warning
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// Inline, dismissible error banner.
class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () =>
                ref.read(providerKeyControllerProvider.notifier).clearError(),
          ),
        ],
      ),
    );
  }
}

/// Centered loading/empty/error pane.
class _PaneMessage extends StatelessWidget {
  const _PaneMessage({required this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon == null)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 28),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
