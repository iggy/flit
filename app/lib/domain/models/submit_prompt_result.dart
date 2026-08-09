import 'package:flit/domain/models/prompt_submit_status.dart';

/// Result of a `prompt.submit` acknowledgement (gateway 0.20).
///
/// The reply still arrives as turn events on [turnEvents]; this is only the
/// disposition the gateway returned for the submission itself.
class SubmitPromptResult {
  const SubmitPromptResult(this.status);

  /// How the gateway disposed of the prompt.
  final PromptSubmitStatus status;
}
