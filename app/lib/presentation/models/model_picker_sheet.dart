import 'package:flutter/material.dart';

/// STUB for ticket P1-12 (model picker). The implementing agent replaces the
/// sheet content but MUST keep the `ModelPickerButton` + `ModelPickerSheet`
/// class names and this file path (the chat app bar references them).
class ModelPickerButton extends StatelessWidget {
  const ModelPickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Select model',
      icon: const Icon(Icons.smart_toy_outlined),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => const ModelPickerSheet(),
        );
      },
    );
  }
}

/// STUB — P1-12 replaces with the provider-grouped model picker.
class ModelPickerSheet extends StatelessWidget {
  const ModelPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Model picker — implemented in ticket P1-12.'),
      ),
    );
  }
}
