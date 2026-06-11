// lib/widgets/entry_form/rating_picker_sheet.dart
import 'package:flutter/material.dart';

class RatingPickerSheet extends StatefulWidget {
  final int? initialRating;

  const RatingPickerSheet({super.key, this.initialRating});

  @override
  State<RatingPickerSheet> createState() => _RatingPickerSheetState();
}

class _RatingPickerSheetState extends State<RatingPickerSheet> {
  int? _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rate your day',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final idx = i + 1;
              final filled = (_rating ?? 0) >= idx;
              return GestureDetector(
                onTap: () {
                  setState(() => _rating = idx);
                  // Pop immediately after selection
                  Navigator.pop(context, idx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: filled ? Colors.amber : color.outlineVariant,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          if (_rating != null)
            TextButton(
              onPressed: () {
                setState(() => _rating = null);
                Navigator.pop(context, -1); // -1 indicates cleared
              },
              child: const Text('Clear rating'),
            ),
        ],
      ),
    );
  }
}
