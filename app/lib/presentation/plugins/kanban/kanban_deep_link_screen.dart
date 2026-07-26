import 'package:flit/application/plugins/plugin_providers.dart';
import 'package:flit/presentation/plugins/kanban/kanban_board_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves a kanban board deep link (ticket P9-02) by selecting the board
/// slug before showing the kanban board screen. The slug comes from the
/// router's `:board` path parameter.
class KanbanDeepLinkScreen extends ConsumerStatefulWidget {
  const KanbanDeepLinkScreen({super.key, required this.boardSlug});

  final String boardSlug;

  @override
  ConsumerState<KanbanDeepLinkScreen> createState() =>
      _KanbanDeepLinkScreenState();
}

class _KanbanDeepLinkScreenState extends ConsumerState<KanbanDeepLinkScreen> {
  @override
  void initState() {
    super.initState();
    // Select the board slug so [kanbanBoardProvider] fetches the right board.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(selectedKanbanBoardProvider.notifier)
            .selectBoard(widget.boardSlug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The KanbanBoardScreen already watches [kanbanBoardProvider], which now
    // reads [selectedKanbanBoardProvider] to determine the slug.
    return const KanbanBoardScreen();
  }
}
