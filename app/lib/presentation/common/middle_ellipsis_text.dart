/// One-line text that, when it does not fit, drops characters from the
/// middle instead of the end, so both ends stay readable. Built for model
/// ids like `qwen/Qwen3.8-Coder:Q4_K_M`, where the quant tag after `:` is
/// what tells two models apart and must not be the part that disappears.
library;

import 'package:flutter/material.dart';

/// The ellipsis [middleEllipsis] inserts.
const String kMiddleEllipsis = '…';

/// [text] cut to [keep] characters (grapheme clusters) plus an ellipsis in
/// the middle; the end gets the extra character when [keep] is odd. Returns
/// [text] unchanged when it already has [keep] characters or fewer.
String middleEllipsis(String text, int keep) {
  final chars = text.characters;
  if (keep >= chars.length) {
    return text;
  }
  if (keep <= 0) {
    return kMiddleEllipsis;
  }
  final tail = (keep + 1) ~/ 2;
  final head = keep - tail;
  return '${chars.take(head)}$kMiddleEllipsis${chars.takeLast(tail)}';
}

/// A single line of [text] that ellipsizes in the middle when it is wider
/// than the space it gets. When it does, a tooltip shows the whole text
/// (unless [tooltip] is false, for callers with a tooltip of their own),
/// and screen readers still read the whole text.
class MiddleEllipsisText extends StatelessWidget {
  const MiddleEllipsisText(
    this.text, {
    this.style,
    this.tooltip = true,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final bool tooltip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shown = _fit(context, constraints.maxWidth);
        final label = Text(
          shown,
          style: style,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          semanticsLabel: text,
        );
        if (shown == text || !tooltip) {
          return label;
        }
        return Tooltip(message: text, child: label);
      },
    );
  }

  /// The longest middle-ellipsized form of [text] that fits [maxWidth].
  String _fit(BuildContext context, double maxWidth) {
    if (!maxWidth.isFinite) {
      return text;
    }
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    try {
      bool fits(String s) {
        painter.text = TextSpan(
          text: s,
          style: (painter.text! as TextSpan).style,
        );
        painter.layout();
        return painter.width <= maxWidth;
      }

      if (fits(text)) {
        return text;
      }
      // Binary search the most characters that still fit.
      var lo = 0;
      var hi = text.characters.length - 1;
      while (lo < hi) {
        final mid = (lo + hi + 1) ~/ 2;
        if (fits(middleEllipsis(text, mid))) {
          lo = mid;
        } else {
          hi = mid - 1;
        }
      }
      return middleEllipsis(text, lo);
    } finally {
      painter.dispose();
    }
  }
}
