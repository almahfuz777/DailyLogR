import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/providers/journal_provider.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final selectedTrashEntriesProvider = StateProvider.autoDispose<Set<String>>((ref) => {});

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider to rebuild when list changes
    ref.watch(journalProvider); 
    
    // Watch selection state
    final selectedTrash = ref.watch(selectedTrashEntriesProvider);

    // Get the deleted entries directly
    final deletedEntries = ref.read(journalProvider.notifier).getDeletedEntries();

    final theme = Theme.of(context);
    final color = theme.colorScheme;

    Widget buildBody() {
      if (deletedEntries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No deleted items',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Items in trash will be permanently deleted after 30 days',
                style: theme.textTheme.bodyMedium?.copyWith(
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
          final id = DayKey.of(DayKey.normalize(entry.date));
          final isSelected = selectedTrash.contains(id);
          
          final now = DateTime.now();
          final daysLeft = 30 - now.difference(entry.deletedAt ?? entry.date).inDays;
          
          return Card(
            elevation: isSelected ? 2 : 0,
            margin: const EdgeInsets.only(bottom: 12),
            color: isSelected ? color.primaryContainer : color.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isSelected 
                  ? BorderSide(color: color.primary, width: 2)
                  : BorderSide(color: color.outlineVariant.withValues(alpha: 0.5), width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (selectedTrash.isNotEmpty) {
                  final notifier = ref.read(selectedTrashEntriesProvider.notifier);
                  if (isSelected) {
                    notifier.state = {...selectedTrash}..remove(id);
                  } else {
                    notifier.state = {...selectedTrash, id};
                  }
                } else {
                  _confirmRestore(context, ref, entry);
                }
              },
              onLongPress: () {
                final notifier = ref.read(selectedTrashEntriesProvider.notifier);
                if (isSelected) {
                  notifier.state = {...selectedTrash}..remove(id);
                } else {
                  notifier.state = {...selectedTrash, id};
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title ?? DayKey.ofLong(entry.date),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                              color: isSelected ? color.onPrimaryContainer : color.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${daysLeft > 0 ? daysLeft : 0} days left • Deleted: ${DateFormat.yMMMd().format(entry.deletedAt ?? entry.date)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected 
                                  ? color.onPrimaryContainer.withValues(alpha: 0.7) 
                                  : color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedTrash.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? color.primary : color.outline,
                      ),
                    ] else ...[
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
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: selectedTrash.isNotEmpty
          ? AppBar(
              backgroundColor: color.surfaceContainerHighest,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(selectedTrashEntriesProvider.notifier).state = {};
                },
              ),
              title: Text('${selectedTrash.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  tooltip: 'Restore Selected',
                  onPressed: () {
                    _confirmBulkRestore(context, ref, selectedTrash);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Delete Permanently',
                  onPressed: () {
                    _confirmBulkDelete(context, ref, selectedTrash);
                  },
                ),
              ],
            )
          : AppBar(
              title: const Text('Recently Deleted'),
            ),
      body: buildBody(),
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

  void _confirmBulkRestore(BuildContext context, WidgetRef ref, Set<String> selectedKeys) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Entries?'),
        content: Text('Restore the ${selectedKeys.length} selected entries back to your journal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final notifier = ref.read(journalProvider.notifier);
              final deletedEntries = notifier.getDeletedEntries();
              final toRestore = deletedEntries.where(
                (e) => selectedKeys.contains(DayKey.of(DayKey.normalize(e.date)))
              ).toList();

              for (final entry in toRestore) {
                await notifier.restoreEntry(entry);
              }

              if (context.mounted) {
                ref.read(selectedTrashEntriesProvider.notifier).state = {};
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${toRestore.length} entries restored')),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete(BuildContext context, WidgetRef ref, Set<String> selectedKeys) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('Permanently delete ${selectedKeys.length} selected entries? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final notifier = ref.read(journalProvider.notifier);
              final deletedEntries = notifier.getDeletedEntries();
              final toDelete = deletedEntries.where(
                (e) => selectedKeys.contains(DayKey.of(DayKey.normalize(e.date)))
              ).toList();

              for (final entry in toDelete) {
                await notifier.permanentlyDeleteEntry(entry);
              }

              if (context.mounted) {
                ref.read(selectedTrashEntriesProvider.notifier).state = {};
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${toDelete.length} entries permanently deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
