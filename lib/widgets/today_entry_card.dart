// lib/widgets/today_entry_card.dart
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown on the dashboard when today's entry already exists.
/// Previews the entry and provides an edit action.
class TodayEntryCard extends ConsumerWidget {
  final JournalEntry entry;

  const TodayEntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Entry",
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DayKey.of(entry.date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => entryEditorSheet(context, ref, initial: entry),
                ),
              ],
            ),

            // Adjective + rating chips
            if (entry.adjective != null || entry.rating != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (entry.adjective != null)
                    Chip(
                      label: Text(entry.adjective!),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (entry.rating != null)
                    Chip(
                      label: Text('⭐ ${entry.rating}/5'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],

            // Optional title
            if (entry.title?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                entry.title!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            // Note preview
            const SizedBox(height: 8),
            Text(
              entry.note,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
