/// Session info bottom sheet (tickets P2-05, P2-06, P2-07, P2-08): app-bar
/// button opening a sheet with usage + context breakdown and compress / undo /
/// save / set-cwd actions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/session_info.dart';
import 'package:flit/application/sessions/session_list.dart';

// Keys for tests.
const Key sessionInfoButtonKey = Key('session_info_button');
const Key sessionInfoCompressKey = Key('session_info_compress');
const Key sessionInfoUndoKey = Key('session_info_undo');
const Key sessionInfoSaveKey = Key('session_info_save');
const Key sessionInfoCwdKey = Key('session_info_cwd');

/// App-bar action for session info: an info icon opening
/// [SessionInfoSheet].
class SessionInfoButton extends ConsumerWidget {
  const SessionInfoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      key: sessionInfoButtonKey,
      tooltip: 'Session info',
      icon: const Icon(Icons.info_outline),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => const SessionInfoSheet(),
        );
      },
    );
  }
}

/// The session info sheet: usage stats, context breakdown, and session
/// actions (compress / undo / save / set-cwd).
class SessionInfoSheet extends ConsumerStatefulWidget {
  const SessionInfoSheet({super.key});

  @override
  ConsumerState<SessionInfoSheet> createState() => _SessionInfoSheetState();
}

class _SessionInfoSheetState extends ConsumerState<SessionInfoSheet> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final liveId = ref.watch(activeSessionProvider).liveId;
    final actions = ref.read(sessionActionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Session',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildUsageSection(),
              const SizedBox(height: 16),
              _buildContextBreakdownSection(),
              const SizedBox(height: 16),
              if (_error != null) _buildErrorBanner(),
              _buildActionsSection(liveId, actions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageSection() {
    final liveUsage = ref.watch(liveUsageProvider);
    final usageAsync = ref.watch(sessionUsageProvider);

    // Prefer live usage; fall back to async fetch.
    final usage = liveUsage ?? usageAsync.value;

    if (usage == null) {
      return switch (usageAsync) {
        AsyncError(:final error) => Text(
          'Could not load usage: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Usage',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (usage.model.isNotEmpty)
          _InfoRow(label: 'Model', value: usage.model),
        _InfoRow(label: 'Total tokens', value: '${usage.total}'),
        _InfoRow(label: 'Input', value: '${usage.input}'),
        _InfoRow(label: 'Output', value: '${usage.output}'),
        _InfoRow(label: 'Calls', value: '${usage.calls}'),
        if (usage.reasoning != null)
          _InfoRow(label: 'Reasoning', value: '${usage.reasoning}'),
        if (usage.contextPercent != null && usage.contextMax != null) ...<Widget>[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (usage.contextPercent ?? 0) / 100),
          const SizedBox(height: 4),
          Text(
            '${usage.contextUsed} / ${usage.contextMax} tokens (${usage.contextPercent}%)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (usage.compressions != null && usage.compressions! > 0)
          _InfoRow(label: 'Compressions', value: '${usage.compressions}'),
      ],
    );
  }

  Widget _buildContextBreakdownSection() {
    final breakdownAsync = ref.watch(contextBreakdownProvider);

    return switch (breakdownAsync) {
      AsyncData(:final value) => value != null && value.categories.isNotEmpty
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Context breakdown',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final category in value.categories)
            _InfoRow(label: category.label, value: '${category.tokens}'),
        ],
      )
          : const SizedBox.shrink(),
      AsyncError(:final error) => Text(
        'Could not load breakdown: $error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildErrorBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: scheme.onErrorContainer),
            onPressed: () => setState(() => _error = null),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(String? liveId, SessionActions actions) {
    final enabled = liveId != null && !_busy;
    final safeId = liveId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ElevatedButton.icon(
              key: sessionInfoCompressKey,
              onPressed: enabled
                  ? () async {
                await _handleCompress(safeId, actions);
              }
                  : null,
              icon: const Icon(Icons.compress),
              label: const Text('Compress context'),
            ),
            ElevatedButton.icon(
              key: sessionInfoUndoKey,
              onPressed: enabled
                  ? () async {
                await _handleUndo(safeId, actions);
              }
                  : null,
              icon: const Icon(Icons.undo),
              label: const Text('Undo last turn'),
            ),
            ElevatedButton.icon(
              key: sessionInfoSaveKey,
              onPressed: enabled
                  ? () async {
                await _handleSave(safeId, actions);
              }
                  : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save conversation'),
            ),
            ElevatedButton.icon(
              key: sessionInfoCwdKey,
              onPressed: enabled
                  ? () async {
                await _handleSetCwd(safeId, actions);
              }
                  : null,
              icon: const Icon(Icons.folder_outlined),
              label: const Text('Set working directory'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleCompress(String liveId, SessionActions actions) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await actions.compress(liveId);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (result == null) {
      ref.invalidate(sessionUsageProvider);
      ref.invalidate(contextBreakdownProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Context compressed')),
      );
    } else {
      setState(() => _error = result);
    }
  }

  Future<void> _handleUndo(String liveId, SessionActions actions) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo last turn?'),
        content: const Text(
          'This will remove the last user prompt and assistant response.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Undo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await actions.undo(liveId);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (result == null) {
      ref.invalidate(sessionUsageProvider);
      ref.invalidate(contextBreakdownProvider);
      // Note: the message list re-render from undo is out of scope for this
      // ticket; the RPC client's event stream will deliver the update.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turn undone')),
      );
    } else {
      setState(() => _error = result);
    }
  }

  Future<void> _handleSave(String liveId, SessionActions actions) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await actions.save(liveId);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation saved')),
      );
    } else {
      setState(() => _error = result);
    }
  }

  Future<void> _handleSetCwd(String liveId, SessionActions actions) async {
    final controller = TextEditingController();
    final cwd = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set working directory'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Working directory',
            hintText: '/path/to/directory',
          ),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (cwd == null || cwd.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await actions.setCwd(liveId, cwd);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Working directory updated')),
      );
    } else {
      setState(() => _error = result);
    }
  }
}

/// A label-value row for usage info.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
