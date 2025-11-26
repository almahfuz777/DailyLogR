// lib/widgets/entry_tile.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';

class EntryTile extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback? onTap;

  const EntryTile({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasTitle = entry.title?.trim().isNotEmpty ?? false;
    final mood = entry.adjective;
    final rating = entry.rating;

    // build a "mood · stars" line if data exists
    String? moodRatingText;
    if (mood != null || rating != null) {
      final parts = <String>[];
      if (mood != null && mood.trim().isNotEmpty) parts.add(mood);
      if (rating != null) parts.add('⭐ $rating/5');
      moodRatingText = parts.join('  •  ');
    }

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: theme.cardColor,

      // Always show the date as the title
      title: Text(
        DayKey.of(entry.date),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        )
      ),

      // Subtitle: title/note snippet + mood/rating line
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (_) {
                if (hasTitle) {
                  final title = entry.title!.trim();
                  final snippet = entry.note.trim();

                  return Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$title: ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,        // bolder title
                            color: theme.colorScheme.onSurface, // strong readable color
                          ),
                        ),
                        TextSpan(
                          text: snippet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                }

                // No title → show note normally
                return Text(
                  entry.note.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                );
              },
            ),

            if (moodRatingText != null) ...[
              const SizedBox(height: 4),
              Text(
                moodRatingText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
