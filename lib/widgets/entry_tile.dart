// lib/widgets/entry_tile.dart
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';

class EntryTile extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EntryTile({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
  });

  // helper method to format date as yyyy-MM-dd
  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.white,

      // Always show the date as the title
      title: Text(
        _dayKey(entry.date),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),

      // Subtitle: title/note snippet + mood/rating line
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasTitle ? entry.title!.trim() : entry.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (moodRatingText != null) ...[
              const SizedBox(height: 4),
              Text(
                moodRatingText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),

      // Edit/Delete actions
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueGrey),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
