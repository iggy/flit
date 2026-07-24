/// Token usage for a turn (wire §7: `message.complete.payload.usage`).
final class Usage {
  const Usage({required this.input, required this.output, this.costUsd});

  /// Input tokens consumed.
  final int input;

  /// Output tokens produced.
  final int output;

  /// Cost in USD (wire `cost_usd`), when reported.
  final double? costUsd;

  @override
  bool operator ==(Object other) {
    return other is Usage &&
        other.input == input &&
        other.output == output &&
        other.costUsd == costUsd;
  }

  @override
  int get hashCode => Object.hash(input, output, costUsd);

  @override
  String toString() =>
      'Usage(input: $input, output: $output, costUsd: $costUsd)';
}
