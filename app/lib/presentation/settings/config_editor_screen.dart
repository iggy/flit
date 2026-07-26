import 'package:flit/application/config/config_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Config editor screen (ticket P4-06). Shows all config sections from
/// `config.show` and provides an affordance to edit arbitrary keys.
class ConfigEditorScreen extends ConsumerWidget {
  const ConfigEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(configShowProvider);
    final editorState = ref.watch(configEditorControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Config Editor')),
      body: Column(
        children: [
          // Warning banner
          if (editorState.warning != null)
            Material(
              color: Colors.orange.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        editorState.warning!,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref
                            .read(configEditorControllerProvider.notifier)
                            .clearWarning();
                      },
                    ),
                  ],
                ),
              ),
            ),
          // Error banner
          if (editorState.error != null)
            Material(
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        editorState.error!,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref
                            .read(configEditorControllerProvider.notifier)
                            .clearError();
                      },
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: configAsync.when(
              data: (sections) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Config sections
                  for (final section in sections) ...[
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final row in section.rows)
                      ListTile(
                        title: Text(row.label),
                        subtitle: Text(row.value),
                        dense: true,
                      ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(),
                  const SizedBox(height: 16),
                  // Edit form
                  _EditKeyForm(),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Error loading config: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditKeyForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EditKeyForm> createState() => _EditKeyFormState();
}

class _EditKeyFormState extends ConsumerState<_EditKeyForm> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(configEditorControllerProvider);

    // Show confirmation dialog when confirmMessage is set
    if (editorState.confirmMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfirmDialog(
          context,
          editorState.confirmMessage!,
          editorState.pendingKey ?? '',
          editorState.pendingValue ?? '',
        );
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit a key', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                border: OutlineInputBorder(),
              ),
              enabled: !editorState.busy,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
              enabled: !editorState.busy,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: editorState.busy
                  ? null
                  : () {
                      final key = _keyController.text.trim();
                      final value = _valueController.text;
                      if (key.isEmpty) {
                        return;
                      }
                      ref
                          .read(configEditorControllerProvider.notifier)
                          .setKey(key, value);
                    },
              child: editorState.busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String message,
    String key,
    dynamic value,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(configEditorControllerProvider.notifier).cancelConfirm();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(configEditorControllerProvider.notifier)
                  .confirmSet(key, value as String);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
