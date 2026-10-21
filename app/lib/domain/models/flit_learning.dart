/// Manual self-learning (flit.v1 `LearningService`): a pass over a finished
/// session proposes lessons for the memory files and skills; nothing is
/// written until a proposal is accepted.
library;

enum FlitLearnAction { add, update, remove }

/// Where a proposal goes: the user memory (every session), the session's
/// project memory, its role's memory file, or a skill's SKILL.md.
enum FlitLearnTarget { user, project, role, skill }

enum FlitLearnStatus { pending, accepted, rejected }

final class FlitLearnProposal {
  const FlitLearnProposal({
    required this.id,
    required this.sessionId,
    required this.action,
    required this.target,
    required this.status,
    this.skill = '',
    this.cue = '',
    this.lesson = '',
    this.evidence = '',
    this.oldText = '',
    this.newText = '',
    this.path = '',
    this.provider = '',
    this.model = '',
  });

  final String id;
  final String sessionId;
  final FlitLearnAction action;
  final FlitLearnTarget target;
  final FlitLearnStatus status;

  /// The skill's name, for [FlitLearnTarget.skill].
  final String skill;

  /// The lesson as the model gave it; [evidence] names turns ("T2, T5").
  final String cue;
  final String lesson;
  final String evidence;

  /// The memory entry or SKILL.md being changed or removed ('' for add).
  final String oldText;

  /// What will be written: a Markdown list item or a whole SKILL.md (''
  /// for remove).
  final String newText;

  /// The file it goes to, on the server.
  final String path;

  /// The model that proposed it.
  final String provider;
  final String model;

  /// "project memory", "skill release", ...
  String get targetLabel => switch (target) {
    FlitLearnTarget.user => 'user memory',
    FlitLearnTarget.project => 'project memory',
    FlitLearnTarget.role => 'role memory',
    FlitLearnTarget.skill => 'skill $skill',
  };
}

/// What one learning pass proposed.
final class FlitLearnResult {
  const FlitLearnResult({
    required this.proposals,
    this.dropped = const <String>[],
    this.provider = '',
    this.model = '',
  });

  final List<FlitLearnProposal> proposals;

  /// Why proposals the model made were left out.
  final List<String> dropped;
  final String provider;
  final String model;
}
