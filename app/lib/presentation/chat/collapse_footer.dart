/// A "Collapse" control for the bottom of a long expanded section, so a
/// reader at the end of pages of thinking or tool output doesn't have to
/// scroll back up to the header to close it.
library;

import 'package:flutter/material.dart';

/// Expanded text longer than this many characters (or lines) gets a footer.
const int collapseFooterMinChars = 800;
const int collapseFooterMinLines = 15;

/// Whether [text] is long enough to warrant a bottom collapse control.
bool needsCollapseFooter(String text) {
  return text.length > collapseFooterMinChars ||
      '\n'.allMatches(text).length >= collapseFooterMinLines;
}

class CollapseFooter extends StatelessWidget {
  const CollapseFooter({required this.onCollapse, super.key});

  /// Collapses the section. The footer then scrolls the section's header
  /// back into view, since collapsing from the bottom would otherwise leave
  /// the reader far below it.
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          onCollapse();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Scrollable.ensureVisible(
                context,
                alignment: 0.1,
                duration: const Duration(milliseconds: 200),
              );
            }
          });
        },
        icon: Icon(Icons.expand_less, size: 18, color: scheme.outline),
        label: Text(
          'Collapse',
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
