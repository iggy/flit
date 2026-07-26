/// Composer prefill provider (ticket P3-03): holds a pending prefill string
/// for the composer field. Used to wire the slash launcher selection → composer.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier holding a pending prefill string for the composer.
/// Null = no pending prefill. Set by the launcher, consumed once by the composer.
final class ComposerPrefillNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void prefill(String text) => state = text;

  void clear() => state = null;
}

final composerPrefillProvider =
    NotifierProvider<ComposerPrefillNotifier, String?>(
      ComposerPrefillNotifier.new,
    );
