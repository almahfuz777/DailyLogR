// lib/widgets/view_entry_sheet.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';

class ViewEntrySheet extends StatelessWidget {
  final JournalEntry entry;
  const ViewEntrySheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final mood = entry.adjective;
    final rating = entry.rating;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with actions (edit, delete, close)
              Row(
                children: [
                  Text(
                    DayKey.of(entry.date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.pop(context, 'edit'),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete),
                    onPressed: () => Navigator.pop(context, 'delete'),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              if (mood != null || rating != null) ...[
                // Mood and rating row
                Row(
                  children: [
                    if (mood != null && mood.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(mood, style: const TextStyle(fontSize: 12)),
                      ),
                    if (mood != null && rating != null)
                      const SizedBox(width: 8),
                    if (rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⭐ $rating/5',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Title
              if ((entry.title?.trim().isNotEmpty ?? false)) ...[
                Text(
                  entry.title!.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
              ],

              // Note
              Text(entry.note, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 16),

              // Last updated timestamp
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Last updated: ${(entry.updatedAt).toLocal().toString().substring(0, 16)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
