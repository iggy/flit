/// "Learn from this session": runs the server's learning pass and lets the
/// user accept, edit or reject each proposed memory entry or skill. Nothing
/// is written until a proposal is accepted.
library;

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_learning.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The composer command, offered in the slash menu with the skills.
const String flitLearnCommand = 'learn';
const FlitSkill flitLearnSkill = FlitSkill(
  name: flitLearnCommand,
  description: 'Review lessons from this session to remember next time',
  source: 'flit',
);

/// Whether [text] is the /learn command.
bool flitIsLearnCommand(String text) =>
    RegExp(r'^/learn\s*$').hasMatch(text.trim());

const Key flitLearnRunningKey = Key('flit_learn_running');
const Key flitLearnEmptyKey = Key('flit_learn_empty');
const String flitLearnAcceptKeyPrefix = 'flit_learn_accept_';
const String flitLearnRejectKeyPrefix = 'flit_learn_reject_';
const String flitLearnEditKeyPrefix = 'flit_learn_edit_';
const String flitLearnTextKeyPrefix = 'flit_learn_text_';

Future<void> showFlitLearnSheet(BuildContext context, String sessionId) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: FlitLearnSheet(sessionId: sessionId),
    ),
  );
}

class FlitLearnSheet extends ConsumerStatefulWidget {
  const FlitLearnSheet({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<FlitLearnSheet> createState() => _FlitLearnSheetState();
}

class _FlitLearnSheetState extends ConsumerState<FlitLearnSheet> {
  bool _running = false;
  String? _error;
  FlitLearnResult? _result;

  /// Proposals as decided so far, by id.
  final Map<String, FlitLearnProposal> _decided = <String, FlitLearnProposal>{};

  /// Proposals being edited: their text field.
  final Map<String, TextEditingController> _editing =
      <String, TextEditingController>{};
  final Set<String> _busy = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    for (final c in _editing.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run() async {
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      setState(() => _error = 'Not connected to a flit server.');
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final result = await repository.learn(widget.sessionId);
      if (mounted) {
        setState(() {
          _result = result;
          _decided.clear();
        });
      }
    } on GatewayException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  Future<void> _decide(FlitLearnProposal p, {required bool accept}) async {
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    setState(() => _busy.add(p.id));
    try {
      final edited = _editing[p.id]?.text;
      final decided = accept
          ? await repository.acceptLearnProposal(p.id, text: edited)
          : await repository.rejectLearnProposal(p.id);
      if (mounted) {
        setState(() {
          _decided[p.id] = decided;
          _editing.remove(p.id)?.dispose();
        });
      }
    } on GatewayException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save it: ${error.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy.remove(p.id));
      }
    }
  }

  void _edit(FlitLearnProposal p) {
    setState(() {
      _editing[p.id] = TextEditingController(text: p.newText);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ListView(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Learn from this session',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Run again',
                  onPressed: _running ? null : _run,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Text(
              'Lessons for next time, for the memory files and skills. '
              'Nothing is saved until you accept it.',
            ),
            const SizedBox(height: 12),
            if (_running)
              const Padding(
                key: flitLearnRunningKey,
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Reading the session. This can take a minute with a '
                      'local model.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (_error != null)
              Text(
                'Could not learn from it: $_error',
                style: TextStyle(color: theme.colorScheme.error),
              )
            else if (result != null) ...<Widget>[
              if (result.proposals.isEmpty)
                const Padding(
                  key: flitLearnEmptyKey,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nothing worth keeping from this session.'),
                ),
              for (final p in result.proposals) _card(context, p),
              if (result.model.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Proposed by ${result.model}'
                    '${result.dropped.isEmpty ? '' : ' · ${result.dropped.length} left out'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, FlitLearnProposal proposal) {
    final theme = Theme.of(context);
    final decided = _decided[proposal.id];
    final p = decided ?? proposal;
    final editing = _editing[p.id];
    final busy = _busy.contains(p.id);
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${_verb(p.action)} ${p.targetLabel}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (decided != null)
                  Chip(
                    label: Text(
                      decided.status == FlitLearnStatus.accepted
                          ? 'Saved'
                          : 'Rejected',
                    ),
                  ),
              ],
            ),
            if (p.evidence.isNotEmpty)
              Text('From ${p.evidence}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            if (p.oldText.isNotEmpty)
              _DiffBlock(
                text: p.oldText,
                style: mono?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.error,
                ),
              ),
            if (editing != null)
              TextField(
                key: Key('$flitLearnTextKeyPrefix${p.id}'),
                controller: editing,
                maxLines: null,
                style: mono,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              )
            else if (p.newText.isNotEmpty)
              _DiffBlock(text: p.newText, style: mono),
            Text(p.path, style: theme.textTheme.labelSmall),
            if (decided == null)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    TextButton(
                      key: Key('$flitLearnRejectKeyPrefix${p.id}'),
                      onPressed: busy ? null : () => _decide(p, accept: false),
                      child: const Text('Reject'),
                    ),
                    if (editing == null && p.action != FlitLearnAction.remove)
                      TextButton(
                        key: Key('$flitLearnEditKeyPrefix${p.id}'),
                        onPressed: busy ? null : () => _edit(p),
                        child: const Text('Edit'),
                      ),
                    FilledButton(
                      key: Key('$flitLearnAcceptKeyPrefix${p.id}'),
                      onPressed: busy ? null : () => _decide(p, accept: true),
                      child: Text(editing == null ? 'Accept' : 'Save'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _verb(FlitLearnAction a) => switch (a) {
    FlitLearnAction.add => 'Add to',
    FlitLearnAction.update => 'Change in',
    FlitLearnAction.remove => 'Remove from',
  };
}

class _DiffBlock extends StatelessWidget {
  const _DiffBlock({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(text.trimRight(), style: style),
    );
  }
}
