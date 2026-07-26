/// Agent configuration (ticket P4-02): fast mode, personality, system prompt.
/// Fetches initial values via `config.get` on mount; shows inline
/// busy/error.
library;

import 'dart:async';

import 'package:flit/application/config/config_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AgentSettingsScreen extends ConsumerStatefulWidget {
  const AgentSettingsScreen({super.key});

  @override
  ConsumerState<AgentSettingsScreen> createState() =>
      _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends ConsumerState<AgentSettingsScreen> {
  late final TextEditingController _personalityController;
  late final TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _personalityController = TextEditingController();
    _promptController = TextEditingController();
    Future<void>.microtask(() {
      ref.read(currentFastProvider.notifier).fetchInitial();
      ref.read(currentPersonalityProvider.notifier).fetchInitial();
      ref.read(currentPromptProvider.notifier).fetchInitial();
    });
  }

  @override
  void dispose() {
    _personalityController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(agentSettingsControllerProvider);
    final currentFast = ref.watch(currentFastProvider);
    final currentPersonality = ref.watch(currentPersonalityProvider);
    final currentPrompt = ref.watch(currentPromptProvider);

    if (_personalityController.text.isEmpty && currentPersonality != null) {
      _personalityController.text = currentPersonality;
    }
    if (_promptController.text.isEmpty && currentPrompt != null) {
      _promptController.text = currentPrompt;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (state.busy) const LinearProgressIndicator(),
          if (state.error != null) _ErrorBanner(message: state.error!),
          const SizedBox(height: 8),
          Text('Fast Mode', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable fast mode'),
            subtitle: const Text('Faster, less thorough responses'),
            value: currentFast ?? false,
            onChanged: state.busy
                ? null
                : (value) => unawaited(
                    ref
                        .read(agentSettingsControllerProvider.notifier)
                        .setFast(value),
                  ),
          ),
          const Divider(height: 32),
          Text('Personality', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _personalityController,
            decoration: const InputDecoration(
              hintText: 'Enter personality name (e.g., "helpful", "concise")',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save Personality'),
              onPressed: state.busy
                  ? null
                  : () {
                      final value = _personalityController.text.trim();
                      if (value.isNotEmpty) {
                        unawaited(
                          ref
                              .read(agentSettingsControllerProvider.notifier)
                              .setPersonality(value),
                        );
                      }
                    },
            ),
          ),
          const Divider(height: 32),
          Text('System Prompt', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              hintText: 'Enter custom system prompt',
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                onPressed: state.busy
                    ? null
                    : () {
                        _promptController.clear();
                        unawaited(
                          ref
                              .read(agentSettingsControllerProvider.notifier)
                              .setPrompt(''),
                        );
                      },
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save Prompt'),
                onPressed: state.busy
                    ? null
                    : () {
                        final value = _promptController.text.trim();
                        unawaited(
                          ref
                              .read(agentSettingsControllerProvider.notifier)
                              .setPrompt(value),
                        );
                      },
              ),
            ],
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
      margin: const EdgeInsets.only(bottom: 8),
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
                ref.read(agentSettingsControllerProvider.notifier).clearError(),
          ),
        ],
      ),
    );
  }
}
