import 'package:flutter/material.dart';

/// Thumbs up / down for rating a turn or a model. [rating] is the current
/// rating (null: none yet).
class FlitRatingButtons extends StatelessWidget {
  const FlitRatingButtons({
    required this.rating,
    required this.onRate,
    this.label,
    super.key,
  });

  final bool? rating;
  final ValueChanged<bool> onRate;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null)
          Text(label!, style: Theme.of(context).textTheme.labelSmall),
        IconButton(
          tooltip: 'Good',
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          color: rating == true ? scheme.primary : scheme.outline,
          onPressed: () => onRate(true),
          icon: Icon(rating == true ? Icons.thumb_up : Icons.thumb_up_outlined),
        ),
        IconButton(
          tooltip: 'Bad',
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          color: rating == false ? scheme.error : scheme.outline,
          onPressed: () => onRate(false),
          icon: Icon(
            rating == false ? Icons.thumb_down : Icons.thumb_down_outlined,
          ),
        ),
      ],
    );
  }
}
