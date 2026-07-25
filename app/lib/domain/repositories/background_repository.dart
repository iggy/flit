import 'package:flit/domain/models/background_task.dart';

/// Detached ("background") agent runs (ticket P5-02) — fire a prompt that
/// runs without blocking the chat turn, and observe its completion.
abstract interface class BackgroundRepository {
  /// `prompt.background` — launch a detached run on [sessionId]. Returns the
  /// server-assigned task id (e.g. "bg_ab12cd").
  Future<String> submit(String sessionId, String text);

  /// The stream of `background.complete` events for [sessionId] (the parent
  /// session the tasks were launched on).
  Stream<BackgroundCompletion> completions(String sessionId);
}
