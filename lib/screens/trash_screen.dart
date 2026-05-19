import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/providers/journal_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider to rebuild when list changes
    ref.watch(journalProvider); 
    
    // Get the deleted entries directly
    final deletedEntries = ref.read(journalProvider.notifier).getDeletedEntries();

    if (deletedEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No deleted items',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Items in trash will be permanently deleted after 30 days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deletedEntries.length,
      itemBuilder: (context, index) {
        final entry = deletedEntries[index];
        final now = DateTime.now();
        final daysLeft = 30 - now.difference(entry.deletedAt ?? entry.date).inDays;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              entry.title ?? DateFormat.yMMMd().format(entry.date),
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
            subtitle: Text(
              '${daysLeft > 0 ? daysLeft : 0} days left\nDeleted: ${DateFormat.yMMMd().format(entry.deletedAt ?? entry.date)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  tooltip: 'Restore',
                  onPressed: () {
                    _confirmRestore(context, ref, entry);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Delete Permanently',
                  onPressed: () {
                    _confirmDelete(context, ref, entry);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRestore(BuildContext context, WidgetRef ref, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Entry?'),
        content: const Text('This entry will be moved back to your journal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(journalProvider.notifier).restoreEntry(entry);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry restored')),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(journalProvider.notifier).permanentlyDeleteEntry(entry);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry permanently deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
