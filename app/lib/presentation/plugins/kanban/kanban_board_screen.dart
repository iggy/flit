import 'package:flutter/material.dart';

/// STUB for ticket P1-15 (kanban board). The implementing agent replaces the
/// body but MUST keep the `KanbanBoardScreen` class name and this file path
/// (the router references it).
class KanbanBoardScreen extends StatelessWidget {
  const KanbanBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kanban')),
      body: const Center(
        child: Text('Kanban board — implemented in ticket P1-15.'),
      ),
    );
  }
}
