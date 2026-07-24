/// Model picker (ticket P1-12): an app-bar button showing the current
/// model, and a provider-grouped bottom sheet with auth badges, a
/// "needs key" disabled state, and the expensive-model confirm dialog
/// (wire §8/§9).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hermes/application/models/model_providers.dart';
import 'package:hermes/domain/models/model_option.dart';

/// App-bar action for model selection: the smart-toy icon plus the current
/// model name as a compact label (when known), opening [ModelPickerSheet].
class ModelPickerButton extends ConsumerWidget {
  const ModelPickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentModelProvider);
    final known = current != null && current.model.isNotEmpty;
    return Tooltip(
      message: 'Select model',
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.smart_toy_outlined, size: 20),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            known ? current.model : 'Model',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => const ModelPickerSheet(),
          );
        },
      ),
    );
  }
}

/// The picker sheet: models grouped by provider (wire §8). Tapping a model
/// calls [ModelPickerController.select]; the sheet closes on a clean apply,
/// shows the expensive-model confirm dialog when the gateway demands it,
/// and shows failures inline.
class ModelPickerSheet extends ConsumerWidget {
  const ModelPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(modelOptionsProvider);
    final pickerState = ref.watch(modelPickerControllerProvider);
    final current = ref.watch(currentModelProvider);

    ref.listen(modelPickerControllerProvider, (previous, next) {
      // Clean apply (was switching, now idle with no confirm/error):
      // close the sheet. The session.info event then refreshes the
      // current model (wire §9).
      final wasSwitching = previous?.switching ?? false;
      if (wasSwitching &&
          !next.switching &&
          next.needsConfirm == null &&
          next.error == null) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
        return;
      }
      // Expensive model: the gateway demands confirmation (wire §9).
      if (next.needsConfirm != null && previous?.needsConfirm == null) {
        unawaited(_showConfirmDialog(context, ref, next.needsConfirm!));
      }
    });

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Select model',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (pickerState.switching) const LinearProgressIndicator(),
          if (pickerState.error != null)
            _ErrorBanner(message: pickerState.error!),
          Flexible(
            child: switch (optionsAsync) {
              AsyncData(:final value) => _buildProviderList(
                context,
                ref,
                providers: value.providers,
                // Prefer the merged tracker (fresh via session.info); fall
                // back to the options fetch itself before the seed lands.
                current:
                    current ??
                    (value.current.model.isEmpty ? null : value.current),
                switching: pickerState.switching,
              ),
              AsyncError(:final error) => _PaneMessage(
                icon: Icons.error_outline,
                text: 'Could not load models: $error',
              ),
              _ => const _PaneMessage(icon: null, text: 'Loading models…'),
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
    required CurrentModel? current,
    required bool switching,
  }) {
    if (providers.isEmpty) {
      return const _PaneMessage(
        icon: Icons.smart_toy_outlined,
        text: 'No providers available.',
      );
    }
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        for (final provider in providers) ...<Widget>[
          _buildProviderHeader(context, provider),
          if (provider.models.isEmpty)
            const ListTile(
              dense: true,
              enabled: false,
              title: Text('No models listed'),
            ),
          for (final model in provider.models)
            _buildModelTile(
              context,
              ref,
              provider: provider,
              model: model,
              isCurrent: current?.model == model,
              switching: switching,
            ),
        ],
      ],
    );
  }

  Widget _buildProviderHeader(BuildContext context, ModelProvider provider) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              provider.name,
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (provider.isCurrent) _Badge(label: 'Current', theme: theme),
          if (provider.authenticated)
            _Badge(
              label: 'Authenticated',
              icon: Icons.verified_user_outlined,
              theme: theme,
            )
          else
            _Badge(
              label: 'Needs key',
              icon: Icons.key_off_outlined,
              theme: theme,
              warning: true,
            ),
        ],
      ),
      // The wire warning (e.g. "no key", §8) explains the disabled state.
      subtitle: provider.warning != null ? Text(provider.warning!) : null,
    );
  }

  Widget _buildModelTile(
    BuildContext context,
    WidgetRef ref, {
    required ModelProvider provider,
    required String model,
    required bool isCurrent,
    required bool switching,
  }) {
    final theme = Theme.of(context);
    // Key entry is Phase 4 — for now providers without credentials are
    // signalled and their rows disabled (ticket P1-12 notes).
    final pickable = provider.authenticated;
    return ListTile(
      dense: true,
      enabled: pickable && !switching,
      title: Text(model),
      subtitle: pickable
          ? null
          : Text(
              'Needs key (${provider.keyEnv ?? 'API key'}) — key entry comes in a later phase.',
            ),
      trailing: isCurrent
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : (pickable ? null : const Icon(Icons.key_off_outlined)),
      onTap: pickable && !switching
          ? () => unawaited(
              ref
                  .read(modelPickerControllerProvider.notifier)
                  .select(
                    ModelOption(providerSlug: provider.slug, model: model),
                  ),
            )
          : null,
    );
  }

  Future<void> _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.paid_outlined),
        title: const Text('Confirm expensive model'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(modelPickerControllerProvider.notifier).cancelConfirm();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(
                ref
                    .read(modelPickerControllerProvider.notifier)
                    .confirmExpensive(),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

/// A small pill used in provider section headers (auth state / current).
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

/// Inline, dismissible error line above the list (a failed `config.set`).
class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                ref.read(modelPickerControllerProvider.notifier).clearError(),
          ),
        ],
      ),
    );
  }
}

/// Centered loading/empty/error pane for the sheet body.
class _PaneMessage extends StatelessWidget {
  const _PaneMessage({required this.icon, required this.text});

  /// Null icon → show a progress indicator instead.
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
