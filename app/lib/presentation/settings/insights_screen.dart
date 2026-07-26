import 'package:flit/application/insights/insights_providers.dart';
import 'package:flit/domain/models/insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Insights screen (ticket P6-03): session/message counts over a rolling
/// window with window selector (7 / 30 / 90 days).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);
    final window = ref.watch(insightsWindowProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _WindowChip(
                  label: '7 days',
                  value: 7,
                  selected: window == 7,
                  onSelected: () =>
                      ref.read(insightsWindowProvider.notifier).set(7),
                ),
                const SizedBox(width: 8),
                _WindowChip(
                  label: '30 days',
                  value: 30,
                  selected: window == 30,
                  onSelected: () =>
                      ref.read(insightsWindowProvider.notifier).set(30),
                ),
                const SizedBox(width: 8),
                _WindowChip(
                  label: '90 days',
                  value: 90,
                  selected: window == 90,
                  onSelected: () =>
                      ref.read(insightsWindowProvider.notifier).set(90),
                ),
              ],
            ),
          ),
          Expanded(
            child: insights.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _InsightsError(
                message: error.toString(),
                onRetry: () => ref.invalidate(insightsProvider),
              ),
              data: (data) {
                if (data == null) {
                  return const _InsightsDisconnected();
                }
                return _InsightsContent(insights: data);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int value;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.insights});

  final Insights insights;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _StatCard(label: 'Sessions', value: insights.sessions.toString()),
              const SizedBox(width: 16),
              _StatCard(label: 'Messages', value: insights.messages.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'over last ${insights.days} days',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _InsightsDisconnected extends StatelessWidget {
  const _InsightsDisconnected();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Not connected to a gateway.'));
  }
}

class _InsightsError extends StatelessWidget {
  const _InsightsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline),
          const SizedBox(height: 8),
          Text(
            'Could not load insights',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
