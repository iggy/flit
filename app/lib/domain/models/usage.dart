/// Token usage for a turn (wire §7: `message.complete.payload.usage`).
final class Usage {
  const Usage({
    required this.input,
    required this.output,
    this.costUsd,
    this.speed,
  });

  /// Input tokens consumed.
  final int input;

  /// Output tokens produced.
  final int output;

  /// Cost in USD (wire `cost_usd`), when reported.
  final double? costUsd;

  /// How fast the model call behind this message was; null when the backend
  /// didn't report or measure it (Hermes never does).
  final CallSpeed? speed;

  @override
  bool operator ==(Object other) {
    return other is Usage &&
        other.input == input &&
        other.output == output &&
        other.costUsd == costUsd &&
        other.speed == speed;
  }

  @override
  int get hashCode => Object.hash(input, output, costUsd, speed);

  @override
  String toString() =>
      'Usage(input: $input, output: $output, costUsd: $costUsd, '
      'speed: $speed)';
}

/// How fast one model call was.
final class CallSpeed {
  const CallSpeed({
    this.timeToFirstTokenMs = 0,
    this.promptTokensPerSecond = 0,
    this.generationTokensPerSecond = 0,
    this.cachedTokens = 0,
    this.inputTokens = 0,
    this.source = '',
  });

  /// Request sent to first streamed token, in milliseconds; 0 if unknown.
  final int timeToFirstTokenMs;

  /// Prompt processing (prefill) and generation speed; 0 if unknown.
  final double promptTokensPerSecond;
  final double generationTokensPerSecond;

  /// Prompt tokens the server reused from its cache, out of [inputTokens].
  final int cachedTokens;
  final int inputTokens;

  /// "llama.cpp" (the server's own timings) or "measured" (timed by flit).
  final String source;

  /// Whether there is any speed worth showing.
  bool get hasSpeed =>
      promptTokensPerSecond > 0 ||
      generationTokensPerSecond > 0 ||
      timeToFirstTokenMs > 0;

  @override
  bool operator ==(Object other) {
    return other is CallSpeed &&
        other.timeToFirstTokenMs == timeToFirstTokenMs &&
        other.promptTokensPerSecond == promptTokensPerSecond &&
        other.generationTokensPerSecond == generationTokensPerSecond &&
        other.cachedTokens == cachedTokens &&
        other.inputTokens == inputTokens &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(
    timeToFirstTokenMs,
    promptTokensPerSecond,
    generationTokensPerSecond,
    cachedTokens,
    inputTokens,
    source,
  );

  @override
  String toString() =>
      'CallSpeed(ttft: ${timeToFirstTokenMs}ms, '
      'prompt: $promptTokensPerSecond tok/s, '
      'gen: $generationTokensPerSecond tok/s, source: $source)';
}
