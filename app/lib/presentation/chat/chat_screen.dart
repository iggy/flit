/// Chat screen (tickets P1-07/P1-08/P1-09): the conversation view.
///
/// - P1-07: message list (user/assistant bubbles, tool cards, typing
///   indicator) + composer with Send/Stop.
/// - P1-08: pending interactive prompts render INLINE at the end of the
///   message list (they appear mid-turn while the assistant is blocked).
/// - P1-09: on arrival (and on every transition of the connection state to
///   ready) a session is bootstrapped via [activeSessionProvider]; all
///   chat/prompt calls use its live id.
/// - P1-16: a transition INTO ready with a previous durable id (i.e. a
///   reconnect, not a fresh connect) RE-BINDS the session via
///   [ActiveSessionNotifier.rebind] (protocol §10) instead of dropping it,
///   and the app bar shows the live connection-state chip.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hermes/application/chat/message_fold.dart';
import 'package:hermes/application/chat/message_list_notifier.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/application/sessions/active_session.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';
import 'package:hermes/domain/models/interactive_prompt.dart';
import 'package:hermes/presentation/chat/approval_prompt_card.dart';
import 'package:hermes/presentation/chat/clarify_prompt_card.dart';
import 'package:hermes/presentation/chat/composer.dart';
import 'package:hermes/presentation/chat/message_bubble.dart';
import 'package:hermes/presentation/common/connection_chip.dart';
import 'package:hermes/presentation/models/model_picker_sheet.dart';
import 'package:hermes/presentation/profiles/profile_menu.dart';
import 'package:hermes/presentation/sessions/session_drawer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    // Arrival path: the connect screen navigates here once connected, so
    // the connection is usually ALREADY ready (no state transition fires
    // the listener below) — kick off the bootstrap after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(connectionStateProvider).value ==
          GatewayConnectionState.ready) {
        _onConnectionReady();
      }
    });
  }

  /// The connection is (or just became) ready: ensure we have a session.
  ///
  /// - Fresh connect (no durable id yet) → [ActiveSessionNotifier.bootstrap]
  ///   creates one; it is idempotent, so a path that races the post-frame
  ///   hook still creates exactly one session.
  /// - RECONNECT (a previous durable id) → [ActiveSessionNotifier.rebind]
  ///   resumes the session we were in (protocol §10, ticket P1-16) instead
  ///   of dropping it; the visible message list survives the reconnecting
  ///   gap because the old live id is kept until the rebind lands.
  void _onConnectionReady() {
    final session = ref.read(activeSessionProvider);
    final notifier = ref.read(activeSessionProvider.notifier);
    if (session.durableId != null) {
      unawaited(notifier.rebind());
      return;
    }
    if (session.liveId != null) {
      // A live id WITHOUT a durable id cannot be resumed — start fresh.
      notifier.clear();
    }
    unawaited(notifier.bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    // Reconnect path: every fresh transition INTO ready re-binds (or
    // bootstraps, on a fresh connect).
    ref.listen(connectionStateProvider, (previous, next) {
      final wasReady = previous?.value == GatewayConnectionState.ready;
      if (next.value == GatewayConnectionState.ready && !wasReady) {
        _onConnectionReady();
      }
    });

    // Gated session died (a cookie-presenting REST call got 401): send the
    // user back to the connect screen to sign in again (protocol §2.2).
    ref.listen(sessionExpiredProvider, (previous, next) {
      if (next && previous != true) {
        ref.read(sessionExpiredProvider.notifier).acknowledge();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired — sign in again.')),
        );
        context.go('/connect');
      }
    });

    final session = ref.watch(activeSessionProvider);
    final connectionState = ref.watch(connectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        // Title is the product name for now; a later wave (P1-12) adds
        // model/profile actions and can surface the session title.
        title: const Text('Hermes'),
        actions: <Widget>[
          // Connection state first (P1-16): a dropped socket shows
          // 'Reconnecting' here while the client backs off and resumes.
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(child: ConnectionChip(state: connectionState.value)),
          ),
          // Feature slots — wired to stubs; P1-10/12/13/14 replace the
          // stub implementations in place (same files, same class names).
          const ModelPickerButton(),
          const ProfileMenuButton(),
          IconButton(
            tooltip: 'Plugins',
            icon: const Icon(Icons.extension_outlined),
            onPressed: () => context.push('/plugins'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const SessionDrawer(),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(child: _buildBody(session)),
            const Composer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ActiveSessionState session) {
    final liveId = session.liveId;
    if (liveId == null) {
      final error = session.error;
      if (error != null) {
        return _BootstrapError(error: error);
      }
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Starting a session…'),
          ],
        ),
      );
    }

    final fold = ref.watch(messageListProvider(liveId));
    if (fold.messages.isEmpty && fold.pendingPrompts.isEmpty) {
      return Center(
        child: Text(
          'No messages yet — say hello.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }
    return _MessageListView(fold: fold, liveId: liveId);
  }
}

/// Error state with a retry affordance (P1-09 acceptance).
class _BootstrapError extends ConsumerWidget {
  const _BootstrapError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 32, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              'Could not start a session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => unawaited(
                ref.read(activeSessionProvider.notifier).bootstrap(),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The conversation list: newest content at the BOTTOM (reversed list).
/// Pending prompts render inline after the last message — i.e. at the
/// visual bottom, where the assistant is blocked waiting (P1-08).
class _MessageListView extends StatelessWidget {
  const _MessageListView({required this.fold, required this.liveId});

  final FoldState fold;
  final String liveId;

  @override
  Widget build(BuildContext context) {
    final prompts = fold.pendingPrompts;
    final messages = fold.messages;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length + prompts.length,
      itemBuilder: (context, index) {
        // Reversed list: index 0 is the visual bottom. Prompts come first
        // (bottom-most, after the last message), oldest prompt top-most.
        if (index < prompts.length) {
          return _PromptCard(
            prompt: prompts[prompts.length - 1 - index],
            liveId: liveId,
          );
        }
        final message =
            messages[messages.length - 1 - (index - prompts.length)];
        return MessageBubble(message: message);
      },
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.liveId});

  final InteractivePrompt prompt;

  /// The live id of the message list this card renders in — the family
  /// arg used for fold-state dismissal (and, for approvals, the
  /// by-session respond call).
  final String liveId;

  @override
  Widget build(BuildContext context) {
    return switch (prompt) {
      ApprovalPrompt() => ApprovalPromptCard(
        prompt: prompt as ApprovalPrompt,
        liveId: liveId,
      ),
      ClarifyPrompt() => ClarifyPromptCard(
        prompt: prompt as ClarifyPrompt,
        liveId: liveId,
      ),
    };
  }
}
