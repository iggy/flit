/// 262144 → "262k", 1500000 → "1.5M".
String formatTokens(int n) {
  if (n >= 1000000) {
    final m = n / 1000000;
    return '${m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).round()}k';
  }
  return '$n';
}
