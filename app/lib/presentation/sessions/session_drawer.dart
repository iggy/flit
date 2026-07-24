import 'package:flutter/material.dart';

/// STUB for ticket P1-10 (session drawer). The implementing agent replaces
/// the body but MUST keep the `SessionDrawer` class name and this file path
/// (the chat screen's Scaffold references it).
class SessionDrawer extends StatelessWidget {
  const SessionDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Sessions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('Session list — implemented in ticket P1-10.'),
            ),
          ],
        ),
      ),
    );
  }
}
