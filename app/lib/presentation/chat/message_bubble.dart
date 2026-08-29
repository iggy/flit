/// Message bubbles (ticket P1-07): user right-aligned in
/// `colorScheme.primaryContainer`, assistant left-aligned on
/// `colorScheme.surface` rendering markdown (docs/design/theming.md
/// conventions). All colors come from `Theme.of(context)` — never
/// hard-coded — so the optional skin swap stays a single seam.
library;

import 'dart:math' as math;

import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/presentation/chat/tool_call_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Key of the streaming ("typing") indicator under an assistant bubble —
/// widget tests find it by key while a turn is in flight.
const Key typingIndicatorKey = Key('typing_indicator');

/// Key of the reasoning ("Thinking…") disclosure above an assistant bubble.
const Key reasoningDisclosureKey = Key('reasoning_disclosure');

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
          child: SelectableText(
            message.text,
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatefulWidget {
  const _AssistantMessage({required this.message});

  final ChatMessage message;

  @override
  State<_AssistantMessage> createState() => _AssistantMessageState();
}

class _AssistantMessageState extends State<_AssistantMessage> {
  bool _contentExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final message = widget.message;
    // `rendered` supersedes `text` when the gateway provides it (§6).
    final content = message.rendered ?? message.text;
    final reasoning = message.reasoning;
    final isLongContent = content.length > 500;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Thinking comes BEFORE the reply, both on the wire (§6) and on
            // screen. Absent reasoning renders nothing at all.
            if (reasoning != null && reasoning.trim().isNotEmpty)
              _ReasoningDisclosure(
                key: reasoningDisclosureKey,
                reasoning: reasoning,
                streaming: message.reasoningStreaming,
              ),
            // Tool cards belong to the middle of a turn. Render them before
            // the assistant's final answer so the answer is visibly last.
            for (final tool in message.toolCalls) ToolCallCard(tool: tool),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!_contentExpanded && isLongContent)
                      Text(
                        '${content.substring(0, 200)}...',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      )
                    else
                      MarkdownBody(data: content, selectable: true),
                    if (isLongContent)
                      SizedBox(
                        height: 32,
                        child: TextButton.icon(
                          onPressed: () => setState(
                            () => _contentExpanded = !_contentExpanded,
                          ),
                          icon: Icon(
                            _contentExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(
                            _contentExpanded
                                ? 'Collapse long output'
                                : 'Show full output',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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

/// The model's extended thinking, as a collapsed-by-default disclosure above
/// the reply (`reasoning.delta` live, `message.complete.reasoning` after).
///
/// While [streaming] it reads "Thinking…" and shows the tail of the text
/// even collapsed, so a long silent thinking phase still looks alive; once
/// the turn ends the header settles to "Thought" and the text stays behind
/// the disclosure rather than disappearing. Expanding is sticky: a user who
/// opens it mid-turn keeps it open through the terminal frame.
class _ReasoningDisclosure extends StatefulWidget {
  const _ReasoningDisclosure({
    required this.reasoning,
    required this.streaming,
    super.key,
  });

  final String reasoning;
  final bool streaming;

  @override
  State<_ReasoningDisclosure> createState() => _ReasoningDisclosureState();
}

class _ReasoningDisclosureState extends State<_ReasoningDisclosure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = widget.reasoning.trim();
    final caption = theme.textTheme.bodySmall?.copyWith(color: scheme.outline);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.psychology_outlined,
                    size: 18,
                    color: scheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.streaming ? 'Thinking…' : 'Thought',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Collapsed + still thinking: trail the latest line so the
                  // user sees movement without opening anything.
                  if (!_expanded && widget.streaming)
                    Expanded(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: caption,
                      ),
                    )
                  else
                    const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: scheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...<Widget>[
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              // Reasoning is prose, not markdown — the gateway ships it raw
              // (and half-streamed markdown renders as noise).
              child: SelectableText(text, style: caption),
            ),
          ],
        ],
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
