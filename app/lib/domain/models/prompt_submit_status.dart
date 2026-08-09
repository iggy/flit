/// Acknowledgement status of a `prompt.submit` RPC (gateway 0.20
/// `_handle_busy_submit`): how the gateway disposed of the submitted prompt.
enum PromptSubmitStatus {
  /// The session was idle: the prompt started streaming immediately
  /// (`{"status":"streaming"}`).
  streaming,

  /// The prompt was injected into the live turn as guidance (steer mode).
  steered,

  /// The live turn was redirected in place (interrupt mode).
  redirected,

  /// The prompt was queued to run after the current turn.
  queued,
}
