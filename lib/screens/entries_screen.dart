// lib/screens/entries_screen.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/entry_detail_sheet.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/widgets/empty_state.dart';
import 'package:dailylogr/widgets/entry_tile.dart';

class EntriesScreen extends StatelessWidget {
  const EntriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<JournalEntry>>(
        valueListenable: HiveService.journalBox.listenable(),
        builder: (context, box, _){
          final entries = box.values.toList()..sort((a,b) => b.date.compareTo(a.date));

          if(entries.isEmpty){
            return const EmptyState();
          }
          
          return ListView.separated(
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
                  builder: (_) => EntryDetailSheet(entry: e),
                );

                if (!context.mounted) return;

                // Handle edit action
                if(action == 'edit'){
                  await openEntryEditSheet(context, e);
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
                      await HiveService.deleteEntry(e);
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}