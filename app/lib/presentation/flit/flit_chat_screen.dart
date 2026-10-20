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
import 'package:flit/presentation/flit/flit_call_status.dart';
import 'package:flit/presentation/flit/flit_compaction.dart';
import 'package:flit/presentation/flit/flit_mcp_sheet.dart';
import 'package:flit/presentation/flit/flit_model_picker.dart';
import 'package:flit/presentation/flit/flit_nav.dart';
import 'package:flit/presentation/flit/flit_prompt_card.dart';
import 'package:flit/presentation/flit/flit_queued_message.dart';
import 'package:flit/presentation/flit/flit_rating.dart';
import 'package:flit/presentation/flit/flit_slash_menu.dart';
import 'package:flit/presentation/flit/flit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app bar's yolo mode toggle, and the confirm button of its dialog.
const Key flitYoloButtonKey = Key('flit_yolo');
const Key flitYoloConfirmKey = Key('flit_yolo_confirm');

/// The composer's send and stop buttons.
const Key flitSendKey = Key('flit_send');
const Key flitStopKey = Key('flit_stop');
const Key flitAnswerNowKey = Key('flit_answer_now');

/// The button that scrolls back to new output after the user scrolled up.
const Key flitJumpToLatestKey = Key('flit_jump_to_latest');

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

  /// Whether the list follows new output. True while the user is at (or
  /// near) the bottom; scrolling up stops it so they can read back while a
  /// turn streams.
  bool _following = true;

  /// New output arrived while not following: offer a jump back down.
  bool _unseen = false;

  /// How close to the bottom still counts as "at the bottom".
  static const double _followSlack = 48;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
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
    final compact = flitCompactInstructions(text);
    if (compact != null) {
      return _compact(compact);
    }
    final fold = ref.read(flitChatProvider(widget.sessionId)).fold;
    // Empty text sends what's queued (after a Stop), if anything is.
    if (_sending || (text.isEmpty && (fold.busy || fold.queued.isEmpty))) {
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
      _jumpToLatest();
    } else {
      _snack('Not sent: $error');
    }
  }

  /// /compact: summarize the older messages. While a turn runs, it waits
  /// for the turn's next step.
  Future<void> _compact(String instructions) async {
    if (_sending) {
      return;
    }
    setState(() => _sending = true);
    final error = await ref
        .read(flitChatProvider(widget.sessionId).notifier)
        .compact(instructions: instructions);
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    if (error == null) {
      _input.clear();
      _jumpToLatest();
    } else {
      _snack('Could not compact: $error');
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

  /// "Answer now" is offered while the model is thinking, on models where
  /// it may work and hasn't been seen not to.
  bool _canAnswerNow(FlitFoldState fold, String provider, String model) {
    final call = fold.call;
    if (!fold.busy ||
        call == null ||
        !call.thinking ||
        call.endRequested ||
        fold.reasoningEndIgnored.contains(call.messageId)) {
      return false;
    }
    for (final m
        in ref.watch(flitModelsProvider).value ?? const <FlitModel>[]) {
      if (m.provider == provider && m.id == model) {
        return m.canEndReasoning;
      }
    }
    return false;
  }

  Future<void> _answerNow() async {
    final error = await ref
        .read(flitChatProvider(widget.sessionId).notifier)
        .endReasoning();
    if (error != null && mounted) {
      _snack('Could not stop the thinking: $error');
    }
  }

  Future<void> _retryCall() async {
    final error = await ref
        .read(flitChatProvider(widget.sessionId).notifier)
        .retryModelCall();
    if (error != null && mounted) {
      _snack('Could not retry: $error');
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
      // Sent even for the current model: after a catalog refresh its
      // context window may have changed, and the server only logs a new
      // ModelChanged (which the header reads) when something did.
      await repository.setModel(
        widget.sessionId,
        provider: choice.provider,
        model: choice.model,
      );
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

  /// Turns yolo mode on (after confirming) or off.
  Future<void> _setYolo({required bool on}) async {
    if (on) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Turn on yolo mode?'),
          content: const Text(
            'Every shell command in this session runs without asking. '
            "Commands matching the server's deny rules are still refused.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: flitYoloConfirmKey,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Turn on'),
            ),
          ],
        ),
      );
      if (ok != true) {
        return;
      }
    }
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    try {
      await repository.setYolo(widget.sessionId, yolo: on);
      ref.invalidate(flitSessionProvider(widget.sessionId));
    } on GatewayException catch (error) {
      if (mounted) {
        _snack('Could not change yolo mode: ${error.message}');
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

  /// Recomputes [_following] from where the user is. It only runs when the
  /// position moves, not when content grows under it, so it reflects where
  /// the user was before new output arrived.
  void _onScroll() {
    final position = _scroll.position;
    final atEnd = position.maxScrollExtent - position.pixels <= _followSlack;
    if (atEnd != _following || (atEnd && _unseen)) {
      setState(() {
        _following = atEnd;
        if (atEnd) {
          _unseen = false;
        }
      });
    }
  }

  /// Follows new output if the user is at the bottom; otherwise flags it.
  void _onGrew() {
    if (_following) {
      _scrollToEnd();
    } else if (!_unseen) {
      setState(() => _unseen = true);
    }
  }

  /// Jumps to the bottom after this frame. The list is lazy, so the extent
  /// can grow once the newly visible items are laid out: keep jumping for a
  /// few frames until it holds.
  void _scrollToEnd([int tries = 4]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      final position = _scroll.position;
      if (position.pixels < position.maxScrollExtent) {
        _scroll.jumpTo(position.maxScrollExtent);
        if (tries > 1) {
          _scrollToEnd(tries - 1);
        }
      }
    });
  }

  void _jumpToLatest() {
    setState(() {
      _following = true;
      _unseen = false;
    });
    _scrollToEnd();
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
          (prev?.fold.queued.length ?? 0) != next.fold.queued.length ||
          (prev?.fold.compactions.length ?? 0) !=
              next.fold.compactions.length ||
          (prev?.fold.compacting == null) != (next.fold.compacting == null) ||
          (next.fold.messages.isNotEmpty && next.fold.messages.last.streaming);
      if (grew) {
        _onGrew();
      }
      // The server names a session from its first message (and may rename
      // it later), so re-read the session when one arrives and after each
      // turn instead of keeping the title it had when the screen opened.
      if (next.fold.reasoningEndIgnored.length >
          (prev?.fold.reasoningEndIgnored.length ?? 0)) {
        if (prev != null && prev.fold.lastSeq > 0) {
          _snack(
            "This model can't be cut short, so flit won't offer "
            '"Answer now" for it again.',
          );
        }
        ref.invalidate(flitModelsProvider);
      }
      if (flitSessionNeedsRefresh(prev?.fold, next.fold)) {
        ref
          ..invalidate(flitSessionProvider(widget.sessionId))
          ..invalidate(flitSessionsProvider)
          ..invalidate(flitAllSessionsProvider);
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
    final yolo = fold.yolo ?? session?.yolo ?? false;
    final contextLength = fold.contextLength > 0
        ? fold.contextLength
        : (session?.contextLength ?? 0);
    final contextTokens = fold.contextTokens > 0
        ? fold.contextTokens
        : (session?.contextTokens ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: flitIsWide(context)
            ? Text(
                session?.displayTitle ?? 'Session',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : FlitBreadcrumb(session: session),
        actions: <Widget>[
          IconButton(
            key: flitYoloButtonKey,
            tooltip: yolo
                ? 'Yolo mode is on: shell commands run without asking'
                : 'Yolo mode is off',
            isSelected: yolo,
            onPressed: () => _setYolo(on: !yolo),
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: Icon(
              Icons.bolt,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
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
              inputTokens: fold.speed?.inputTokens ?? 0,
              cachedTokens: fold.speed?.cachedTokens ?? 0,
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
              child:
                  fold.messages.isEmpty &&
                      fold.prompts.isEmpty &&
                      fold.queued.isEmpty
                  ? Center(
                      child: Text(
                        chat.link == FlitLink.offline
                            ? 'Not connected to a flit server.'
                            : 'Send a message to start.',
                      ),
                    )
                  : Stack(
                      children: <Widget>[
                        _messageList(fold, notifier),
                        if (_unseen)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: FilledButton.tonalIcon(
                                key: flitJumpToLatestKey,
                                onPressed: _jumpToLatest,
                                icon: const Icon(Icons.arrow_downward),
                                label: const Text('Jump to latest'),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (fold.busy && fold.call != null)
              FlitCallStatus(
                call: fold.call!,
                onRetry: _retryCall,
                onStop: _interrupt,
              ),
            FlitTodoPanel(todos: fold.todos),
            FlitSlashMenu(
              controller: _input,
              skills: <FlitSkill>[
                flitCompactSkill,
                ...?ref.watch(flitSkillsProvider(widget.sessionId)).value,
              ],
            ),
            _Composer(
              controller: _input,
              busy: fold.busy,
              sending: _sending,
              onSend: _send,
              onStop: _interrupt,
              queued: fold.queued.length,
              onAnswerNow: _canAnswerNow(fold, provider, model)
                  ? _answerNow
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageList(FlitFoldState fold, FlitChatNotifier notifier) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        for (var i = 0; i < fold.messages.length; i++) ...<Widget>[
          for (final c in fold.compactions)
            if (c.beforeIndex == i)
              FlitCompactionMarkerView(
                key: ValueKey<String>(c.compactionId),
                marker: c,
              ),
          // Greyed out once only a compaction summary of it reaches the
          // model; still there to scroll back through.
          Opacity(
            opacity: fold.summarized(i) ? flitSummarizedOpacity : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
            ),
          ),
        ],
        for (final c in fold.compactions)
          if (c.beforeIndex >= fold.messages.length)
            FlitCompactionMarkerView(
              key: ValueKey<String>(c.compactionId),
              marker: c,
            ),
        if (fold.compacting != null)
          FlitCompactingRow(compacting: fold.compacting!),
        for (final q in fold.queued)
          FlitQueuedBubble(
            key: ValueKey<String>(q.queueId),
            message: q,
            turnRunning: fold.busy,
            onEdit: (text) async {
              final error = await notifier.editQueued(q.queueId, text);
              if (error != null && mounted) {
                _snack('Could not edit: $error');
              }
            },
            onCancel: () async {
              final error = await notifier.cancelQueued(q.queueId);
              if (error != null && mounted) {
                _snack('Could not cancel: $error');
              }
            },
          ),
        for (final p in fold.prompts)
          FlitPromptCard(
            key: ValueKey<String>(p.promptId),
            prompt: p,
            onAnswer: ({required allow, forSession = false}) => notifier.answer(
              p.promptId,
              allow: allow,
              forSession: forSession,
            ),
          ),
      ],
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
    this.queued = 0,
    this.onAnswerNow,
  });

  /// Shown beside Stop while the model is thinking, where it can work.
  final VoidCallback? onAnswerNow;

  final TextEditingController controller;
  final bool busy;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onStop;

  /// Messages waiting in the queue.
  final int queued;

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
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: busy
                    ? 'The agent is working; messages wait for its next step'
                    : queued > 0
                    ? 'Message flit (queued messages go first)'
                    : 'Message flit',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (busy && onAnswerNow != null) ...<Widget>[
            IconButton.filledTonal(
              key: flitAnswerNowKey,
              tooltip: 'Stop thinking and answer now',
              onPressed: onAnswerNow,
              icon: const Icon(Icons.fast_forward),
            ),
            const SizedBox(width: 4),
          ],
          if (busy) ...<Widget>[
            IconButton.filledTonal(
              key: flitStopKey,
              tooltip: 'Stop',
              onPressed: onStop,
              icon: const Icon(Icons.stop),
            ),
            const SizedBox(width: 4),
          ],
          IconButton.filled(
            key: flitSendKey,
            tooltip: busy
                ? 'Queue for the agent\'s next step'
                : queued > 0
                ? 'Send (with the queued messages)'
                : 'Send',
            onPressed: sending ? null : onSend,
            icon: Icon(busy ? Icons.schedule_send : Icons.send),
          ),
        ],
      ),
    );
  }
}
