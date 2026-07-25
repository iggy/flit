import 'package:flit/domain/models/learning_journey.dart';

/// Intent-level learning operations (tickets P6-01, P6-02).
abstract interface class LearningRepository {
  /// `learning.frames {frames:2}` → structured journey timeline.
  Future<LearningJourney> frames();

  /// `learning.detail {id}` → full node detail.
  Future<LearningNodeDetail> detail(String id);

  /// `learning.edit {id, content}` → edit mutation result.
  Future<LearningMutationResult> edit(String id, String content);

  /// `learning.delete {id}` → delete mutation result.
  Future<LearningMutationResult> delete(String id);
}
