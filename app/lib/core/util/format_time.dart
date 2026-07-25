/// Small timestamp formatters (P3-06). Avoids a dependency on `intl` for
/// what is only a handful of human-readable stamps in the subagent surface.
library;

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _pad(int value) => value.toString().padLeft(2, '0');

/// `Jan 5, 2026 14:03` — date + minutes, no seconds.
String formatDateMinutes(DateTime dt) {
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year} '
      '${_pad(dt.hour)}:${_pad(dt.minute)}';
}

/// `Jan 5, 2026 14:03:07` — date + seconds.
String formatDateSeconds(DateTime dt) {
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year} '
      '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
}

/// `Jan 5 14:03` — short month/day + minutes (snapshot labels).
String formatShortDateMinutes(DateTime dt) {
  return '${_months[dt.month - 1]} ${dt.day} '
      '${_pad(dt.hour)}:${_pad(dt.minute)}';
}
