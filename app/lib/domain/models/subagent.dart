/// A subagent run by the agent tool: what it was asked, the model it runs
/// on, how it's going, and its own conversation.
library;

import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/deep_equals.dart';

/// What a subagent may do: [explore] only reads; [build] has the
/// session's tools and permission rules.
enum SubagentKind { explore, build, unknown }

enum SubagentStatus { running, done, stepLimit, cancelled, error }

final class Subagent {
  const Subagent({
    required this.kind,
    this.provider = '',
    this.model = '',
    this.task = '',
    this.maxSteps = 0,
    this.status = SubagentStatus.running,
    this.steps = 0,
    this.report = '',
    this.error = '',
    this.transcript = const <ChatMessage>[],
  });

  final SubagentKind kind;
  final String provider;
  final String model;

  /// What it was asked to do.
  final String task;

  /// Its cap on model calls.
  final int maxSteps;
  final SubagentStatus status;

  /// Model calls it made, once done.
  final int steps;

  /// Its final report (the tool result the agent sees), once done.
  final String report;
  final String error;

  /// Its own conversation: its task, replies and tool calls.
  final List<ChatMessage> transcript;

  Subagent copyWith({
    SubagentStatus? status,
    int? steps,
    String? report,
    String? error,
    List<ChatMessage>? transcript,
  }) {
    return Subagent(
      kind: kind,
      provider: provider,
      model: model,
      task: task,
      maxSteps: maxSteps,
      status: status ?? this.status,
      steps: steps ?? this.steps,
      report: report ?? this.report,
      error: error ?? this.error,
      transcript: transcript ?? this.transcript,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Subagent &&
        other.kind == kind &&
        other.provider == provider &&
        other.model == model &&
        other.task == task &&
        other.maxSteps == maxSteps &&
        other.status == status &&
        other.steps == steps &&
        other.report == report &&
        other.error == error &&
        deepListEquals(other.transcript, transcript);
  }

  @override
  int get hashCode => Object.hash(
    kind,
    provider,
    model,
    task,
    maxSteps,
    status,
    steps,
    report,
    error,
    Object.hashAll(transcript),
  );

  @override
  String toString() =>
      'Subagent(${kind.name} on $provider/$model, ${status.name}, '
      '${transcript.length} messages)';
}
