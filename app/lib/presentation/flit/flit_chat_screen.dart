/// One flit session: the live conversation, pending prompts, and a composer.
/// Several devices can have the same session open; they all show the same
/// log, and any of them can answer a prompt.
library;

import 'package:flit/application/flit/flit_chat_notifier.dart';
import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/chat/message_bubble.dart';
import 'package:flit/presentation/flit/flit_mcp_sheet.dart';
import 'package:flit/presentation/flit/flit_model_picker.dart';
import 'package:flit/presentation/flit/flit_prompt_card.dart';
import 'package:flit/presentation/flit/flit_rating.dart';
import 'package:flit/presentation/flit/flit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlitChatScreen extends ConsumerStatefulWidget {
  const FlitChatScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<FlitChatScreen> createState() => _FlitChatScreenState();
}

class _FlitChatScreenState extends ConsumerState<FlitChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Phones kill sockets in the background; catch up straight away.
    if (state == AppLifecycleState.resumed) {
      ref.read(flitChatProvider(widget.sessionId).notifier).reconnectNow();
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    final error = await ref
        .read(flitChatProvider(widget.sessionId).notifier)
        .send(text);
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    if (error == null) {
      _input.clear();
    } else {
      _snack('Not sent: $error');
    }
  }

  Future<void> _interrupt() async {
    final error = await ref
        .read(flitChatProvider(widget.sessionId).notifier)
        .interrupt();
    if (error != null && mounted) {
      _snack('Could not stop: $error');
    }
  }

  Future<void> _changeModel(
    String provider,
    String model,
    String effort,
  ) async {
    final choice = await showFlitModelPicker(
      context,
      provider: provider,
      model: model,
      effort: effort,
      onRateCurrent: (good) => ref
          .read(flitChatProvider(widget.sessionId).notifier)
          .rateModel(good: good),
    );
    if (choice == null) {
      return;
    }
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    try {
      if (choice.provider != provider || choice.model != model) {
        await repository.setModel(
          widget.sessionId,
          provider: choice.provider,
          model: choice.model,
        );
      }
      if (choice.effort != effort) {
        await repository.setEffort(widget.sessionId, choice.effort);
      }
      ref.invalidate(flitSessionProvider(widget.sessionId));
    } on GatewayException catch (error) {
      if (mounted) {
        _snack('Could not change the model: ${error.message}');
      }
    }
  }

  /// Turn results can be rated on the last assistant message of a finished
  /// model call that produced text.
  static bool _rateable(FlitFoldState fold, int i) {
    final m = fold.messages[i];
    return m.role == MessageRole.assistant &&
        !m.streaming &&
        m.text.trim().isNotEmpty &&
        i < fold.messageIds.length &&
        fold.messageIds[i] != null;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(flitSessionProvider(widget.sessionId)).value;
    final chat = ref.watch(flitChatProvider(widget.sessionId));
    final fold = chat.fold;
    final notifier = ref.read(flitChatProvider(widget.sessionId).notifier);

    ref.listen(flitChatProvider(widget.sessionId), (prev, next) {
      final grew =
          (prev?.fold.messages.length ?? 0) != next.fold.messages.length ||
          (prev?.fold.prompts.length ?? 0) != next.fold.prompts.length ||
          (next.fold.messages.isNotEmpty && next.fold.messages.last.streaming);
      if (grew) {
        _scrollToEnd();
      }
    });

    final provider = fold.provider.isNotEmpty
        ? fold.provider
        : (session?.provider ?? '');
    final model = fold.model.isNotEmpty ? fold.model : (session?.model ?? '');
    final taskState = fold.lastSeq > 0
        ? fold.taskState
        : (session?.state ?? FlitTaskState.idle);
    final effort = fold.effort ?? session?.effort ?? '';
    final contextLength = fold.contextLength > 0
        ? fold.contextLength
        : (session?.contextLength ?? 0);
    final contextTokens = fold.contextTokens > 0
        ? fold.contextTokens
        : (session?.contextTokens ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          session?.displayTitle ?? 'Session',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'MCP servers',
            onPressed: () => showFlitMcpSheet(context, widget.sessionId),
            icon: const Icon(Icons.extension_outlined),
          ),
          IconButton(
            tooltip: 'Change model',
            onPressed: () => _changeModel(provider, model, effort),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            FlitStatusStrip(
              provider: provider,
              model: model,
              effort: effort,
              contextTokens: contextTokens,
              contextLength: contextLength,
              state: taskState,
              generationTokensPerSecond: fold.speed?.generationTokensPerSecond,
              timeToFirstTokenMs: fold.speed?.timeToFirstTokenMs,
              onModelTap: () => _changeModel(provider, model, effort),
            ),
            if (chat.link == FlitLink.reconnecting)
              MaterialBanner(
                content: Text('Reconnecting… ${chat.linkError ?? ''}'.trim()),
                leading: const Icon(Icons.cloud_off),
                actions: <Widget>[
                  TextButton(
                    onPressed: notifier.reconnectNow,
                    child: const Text('Retry now'),
                  ),
                ],
              ),
            if (session != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    session.workingDir,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: fold.messages.isEmpty && fold.prompts.isEmpty
                  ? Center(
                      child: Text(
                        chat.link == FlitLink.offline
                            ? 'Not connected to a flit server.'
                            : 'Send a message to start.',
                      ),
                    )
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      children: <Widget>[
                        for (
                          var i = 0;
                          i < fold.messages.length;
                          i++
                        ) ...<Widget>[
                          MessageBubble(message: fold.messages[i]),
                          if (_rateable(fold, i))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FlitRatingButtons(
                                rating: fold.ratings[fold.messageIds[i]],
                                onRate: (good) async {
                                  final error = await notifier.rateTurn(
                                    fold.messageIds[i]!,
                                    good: good,
                                  );
                                  if (error != null && mounted) {
                                    _snack('Could not rate: $error');
                                  }
                                },
                              ),
                            ),
                        ],
                        for (final p in fold.prompts)
                          FlitPromptCard(
                            key: ValueKey<String>(p.promptId),
                            prompt: p,
                            onAnswer: ({required allow}) =>
                                notifier.answer(p.promptId, allow: allow),
                          ),
                      ],
                    ),
            ),
            FlitTodoPanel(todos: fold.todos),
            _Composer(
              controller: _input,
              busy: fold.busy,
              sending: _sending,
              onSend: _send,
              onStop: _interrupt,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.sending,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final bool busy;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 6,
              textInputAction: TextInputAction.send,
              onSubmitted: busy ? null : (_) => onSend(),
              decoration: InputDecoration(
                hintText: busy ? 'The agent is working…' : 'Message flit',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            IconButton.filledTonal(
              tooltip: 'Stop',
              onPressed: onStop,
              icon: const Icon(Icons.stop),
            )
          else
            IconButton.filled(
              tooltip: 'Send',
              onPressed: sending ? null : onSend,
              icon: const Icon(Icons.send),
            ),
        ],
      ),
    );
  }
}
