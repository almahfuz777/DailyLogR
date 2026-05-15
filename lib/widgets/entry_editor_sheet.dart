// lib/widgets/entry_editor_sheet.dart
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/entry_form.dart';

/// Opens the entry bottom sheet for both **creating** and **editing**.
Future<void> entryEditorSheet(
  BuildContext context, {
  JournalEntry? initial,
}) async {
  final isEdit = initial != null;

  // Guard: enforce the 4-day edit window *before* any async gap.
  if (isEdit && !DayKey.isWithinEditWindow(initial.date)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You can only edit entries from the last 4 days.'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(12),
      ),
    );
    return;
  }

  final updatedEntry = await showModalBottomSheet<JournalEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Scaffold(
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      body: EntryForm(initial: initial),
    ),
  );

  if (updatedEntry == null) return;

  // Persist changes to Hive
  try {
    if (isEdit) {
      await HiveService.updateEntry(initial, updatedEntry);
    } else {
      await HiveService.createEntry(updatedEntry);
    }
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
