final class ReasoningOption {
  const ReasoningOption({required this.value, this.label});

  final String value;

  final String? label;

  static const List<ReasoningOption> defaults = <ReasoningOption>[
    ReasoningOption(value: 'high', label: 'High'),
    ReasoningOption(value: 'medium', label: 'Medium'),
    ReasoningOption(value: 'low', label: 'Low'),
  ];

  @override
  bool operator ==(Object other) {
    return other is ReasoningOption && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ReasoningOption(value: $value, label: $label)';
}
