/// Background tasks browser (P5-02).
library;

import 'package:flit/application/background/background_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackgroundScreen extends ConsumerWidget {
  const BackgroundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backgroundTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Background tasks')),
      body: Column(
        children: <Widget>[
          _BackgroundComposer(
            busy: state.busy,
            onSubmit: (text) {
              ref.read(backgroundTasksProvider.notifier).submit(text);
            },
          ),
          if (state.error != null)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                title: Text(
                  state.error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  onPressed: () {
                    ref.read(backgroundTasksProvider.notifier).clearError();
                  },
                ),
              ),
            ),
          if (state.tasks.isEmpty)
            const Expanded(
              child: Center(child: Text('No background tasks yet.')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                  final task = state.tasks[index];
                  final title = task.prompt.isNotEmpty
                      ? task.prompt
                      : task.taskId;
                  final subtitle = task.done ? (task.result ?? '') : 'Running…';
                  return ListTile(
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: task.done
                        ? const Icon(Icons.check_circle)
                        : const SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BackgroundComposer extends StatefulWidget {
  const _BackgroundComposer({required this.busy, required this.onSubmit});

  final bool busy;
  final void Function(String text) onSubmit;

  @override
  State<_BackgroundComposer> createState() => _BackgroundComposerState();
}

class _BackgroundComposerState extends State<_BackgroundComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter a background prompt',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: widget.busy ? null : (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8.0),
          FilledButton(
            onPressed: widget.busy ? null : _submit,
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }
}
