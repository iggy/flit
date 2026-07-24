import 'package:flutter/material.dart';

/// STUB for ticket P1-13 (profile dropdown). The implementing agent replaces
/// the menu content but MUST keep the `ProfileMenuButton` class name and this
/// file path (the chat app bar references it).
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profiles',
      icon: const Icon(Icons.person_outline),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile dropdown — implemented in ticket P1-13.'),
          ),
        );
      },
    );
  }
}
