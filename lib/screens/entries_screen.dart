// lib/screens/entries_screen.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/view_entry_sheet.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/widgets/empty_state.dart';
import 'package:dailylogr/screens/trash_screen.dart';
import 'package:dailylogr/widgets/entry_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/journal_provider.dart';

class EntriesScreen extends ConsumerWidget {
  const EntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider);

    if (entries.isEmpty) {
      return const EmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: entries.length,
            separatorBuilder: (context, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = entries[i];

              return EntryTile(
                key: ValueKey(DayKey.of(DayKey.normalize(e.date))),
                entry: e,
                onTap: () async {
                  // Show detail sheet
                  final action = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ViewEntrySheet(entry: e),
                  );

                  if (!context.mounted) return;

                  // Handle edit action
                  if (action == 'edit') {
                    await entryEditorSheet(context, ref, initial: e);
                  }
                  // Handle delete action
                  else if (action == 'delete') {
                    final key = DayKey.of(DayKey.normalize(e.date));
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete entry?'),
                        content: Text('Delete $key?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (!context.mounted) return;

                    if (confirm == true) {
                      await ref.read(journalProvider.notifier).deleteEntry(e);
                    }
                  }
                },
              );
            },
          ),
        ),
        
        // Anchored bottom button
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Recently Deleted'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Recently Deleted')),
                  body: const TrashScreen(),
                )),
              );
            },
          ),
        ),
      ],
    );
  }
}
