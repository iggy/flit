/// Message bubbles (ticket P1-07): user right-aligned in
/// `colorScheme.primaryContainer`, assistant left-aligned on
/// `colorScheme.surface` rendering markdown (docs/design/theming.md
/// conventions). All colors come from `Theme.of(context)` — never
/// hard-coded — so the optional skin swap stays a single seam.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hermes/domain/models/chat_message.dart';
import 'package:hermes/presentation/chat/tool_call_card.dart';

/// Key of the streaming ("typing") indicator under an assistant bubble —
/// widget tests find it by key while a turn is in flight.
const Key typingIndicatorKey = Key('typing_indicator');

/// One message in the chat list. User messages render as plain-text
/// bubbles; assistant/system messages render markdown plus their tool
/// calls, a typing indicator while streaming, and a terminal status
/// caption (interrupted / error).
class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.role == MessageRole.user) {
      return _UserBubble(message: message);
    }
    return _AssistantMessage(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // `rendered` supersedes `text` when the gateway provides it (§6).
    final content = message.rendered ?? message.text;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (content.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: MarkdownBody(data: content, selectable: true),
              ),
            for (final tool in message.toolCalls) ToolCallCard(tool: tool),
            if (message.streaming)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 2, bottom: 4),
                child: TypingIndicator(key: typingIndicatorKey),
              ),
            if (message.terminalStatus == MessageTerminalStatus.interrupted)
              _StatusCaption(
                icon: Icons.stop_circle_outlined,
                label: 'Interrupted',
                color: scheme.outline,
              ),
            if (message.terminalStatus == MessageTerminalStatus.error)
              _StatusCaption(
                icon: Icons.error_outline,
                label: 'Error',
                color: scheme.error,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCaption extends StatelessWidget {
  const _StatusCaption({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// A subtle three-dot typing indicator shown while deltas are still
/// arriving. Animates continuously — callers must remove it when the
/// terminal event lands (the fold flips `streaming` off).
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < 3; i++) ...<Widget>[
              _Dot(
                color: color,
                // Staggered sine pulse per dot.
                opacity:
                    0.3 +
                    0.7 *
                        (0.5 +
                            0.5 *
                                math.sin(
                                  2 * math.pi * (_controller.value + i / 3),
                                )),
              ),
              if (i < 2) const SizedBox(width: 4),
            ],
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
