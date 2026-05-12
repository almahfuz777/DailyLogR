// lib/utils/entry_creator_sheet.dart
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/widgets/entry_form.dart';

/// Opens the entry editor as a modal bottom sheet.
/// If the user saves, the entry is persisted via HiveService.
Future<void> openEntryCreatorSheet(
  BuildContext context, {
  JournalEntry? initial,
}) async {
  final result = await showModalBottomSheet<JournalEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: EntryForm(initial: initial),
      );
    },
  );

  if (result == null) return;

  try {
    await HiveService.createEntry(result);
  } on JournalEntryConflictException catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An entry already exists for ${error.dateKey}'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}