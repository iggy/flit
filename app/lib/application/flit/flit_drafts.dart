/// Unsent composer text, per session, so it survives leaving the session
/// (say, to copy something from another one) and coming back. A session's
/// chat screen is rebuilt from scratch each time it is opened, so its text
/// field can't hold the draft itself.
///
/// Kept in memory for the app's lifetime; not persisted across restarts.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Composer drafts keyed by session id. Plain storage, not reactive: the
/// composer reads its draft once when it opens and writes on every change,
/// and nothing needs to rebuild when a draft changes.
class FlitDraftStore {
  final Map<String, String> _drafts = <String, String>{};

  /// The unsent text for [sessionId], or '' if there is none.
  String read(String sessionId) => _drafts[sessionId] ?? '';

  /// Stores [text] as [sessionId]'s draft; empty text clears it.
  void write(String sessionId, String text) {
    if (text.isEmpty) {
      _drafts.remove(sessionId);
    } else {
      _drafts[sessionId] = text;
    }
  }

  /// Forgets [sessionId]'s draft (after it was sent).
  void clear(String sessionId) => _drafts.remove(sessionId);
}

/// The app-wide draft store.
final flitDraftStoreProvider = Provider<FlitDraftStore>(
  (ref) => FlitDraftStore(),
);
