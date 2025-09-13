// lib/widgets/entry_list.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/widgets/empty_state.dart';
import 'package:dailylogr/widgets/entry_tile.dart';


class EntryList extends StatelessWidget {
  const EntryList({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: HiveService.journalBox.listenable(),
        builder: (context, Box<JournalEntry> box, _){
          final entries = box.values.toList()..sort((a,b) => b.date.compareTo(a.date));

          if(entries.isEmpty){
            return const EmptyState();
          }
          
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final e = entries[i];
              return EntryTile(entry: e);
            },
          );
        },
    );
  }
}