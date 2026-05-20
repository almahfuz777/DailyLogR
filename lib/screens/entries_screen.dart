// lib/screens/entries_screen.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/widgets/empty_state.dart';
import 'package:dailylogr/screens/trash_screen.dart';
import 'package:dailylogr/widgets/entry_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/journal_provider.dart';

final selectedEntriesProvider = StateProvider<Set<String>>((ref) => {});

class EntriesScreen extends ConsumerWidget {
  const EntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider);
    final selectedEntries = ref.watch(selectedEntriesProvider);

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
              final id = DayKey.of(DayKey.normalize(e.date));
              final isSelected = selectedEntries.contains(id);

              return EntryTile(
                key: ValueKey(id),
                entry: e,
                isSelected: isSelected,
                onTap: () {
                  if (selectedEntries.isNotEmpty) {
                    // Selection mode active
                    final notifier = ref.read(selectedEntriesProvider.notifier);
                    if (isSelected) {
                      notifier.state = {...selectedEntries}..remove(id);
                    } else {
                      notifier.state = {...selectedEntries, id};
                    }
                  } else {
                    // Normal mode - edit
                    entryEditorSheet(context, ref, initial: e);
                  }
                },
                onLongPress: () {
                  final notifier = ref.read(selectedEntriesProvider.notifier);
                  if (isSelected) {
                    notifier.state = {...selectedEntries}..remove(id);
                  } else {
                    notifier.state = {...selectedEntries, id};
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
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}
