/// Appearance settings screen (ticket P9-07): Hermes skin opt-in toggle.
library;

import 'package:flit/application/config/skin_providers.dart';
import 'package:flit/domain/models/gateway_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Appearance settings screen: skin toggle, name display, and color swatches.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinProvider);
    final skinEnabled = ref.watch(skinEnabledProvider);
    final hasSkin = skin != null && skin.isUsable;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            SwitchListTile(
              title: const Text('Match Hermes skin'),
              subtitle: Text(
                hasSkin
                    ? 'Use the color palette pushed by the connected gateway'
                    : 'No skin available from the gateway',
              ),
              value: skinEnabled,
              onChanged: hasSkin
                  ? (enabled) => ref
                        .read(skinEnabledProvider.notifier)
                        .setEnabled(enabled)
                  : null,
            ),
            if (hasSkin) ...[const Divider(), _SkinInfoSection(skin: skin)],
          ],
        ),
      ),
    );
  }
}

class _SkinInfoSection extends ConsumerWidget {
  const _SkinInfoSection({required this.skin});

  final GatewaySkin skin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enabled = ref.watch(skinEnabledProvider);

    // Read the mapped scheme to show swatches.
    final lightScheme = enabled
        ? ref.watch(appLightThemeProvider).colorScheme
        : null;
    final darkScheme = enabled
        ? ref.watch(appDarkThemeProvider).colorScheme
        : null;

    final agentName = skin.branding['agent_name'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Current skin',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text('Name: ${skin.name}', style: theme.textTheme.bodyMedium),
          if (agentName != null && agentName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Agent: $agentName', style: theme.textTheme.bodyMedium),
          ],
          if (enabled && lightScheme != null) ...[
            const SizedBox(height: 16),
            Text(
              'Light mode colors',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            _ColorSwatchRow(scheme: lightScheme),
          ],
          if (enabled && darkScheme != null) ...[
            const SizedBox(height: 16),
            Text(
              'Dark mode colors',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            _ColorSwatchRow(scheme: darkScheme),
          ],
        ],
      ),
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _ColorSwatch(label: 'Primary', color: scheme.primary),
        const SizedBox(width: 8),
        _ColorSwatch(label: 'Surface', color: scheme.surface),
        const SizedBox(width: 8),
        _ColorSwatch(label: 'Error', color: scheme.error),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
