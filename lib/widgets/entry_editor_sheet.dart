// lib/widgets/entry_editor_sheet.dart
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/entry_form.dart';

/// Opens the editor for an existing entry in a bottom sheet,
/// enforces the 4-day edit window, and persists via HiveService.
Future<void> openEntryEditSheet(
  BuildContext context,
  JournalEntry prevEntry,
) async {
  // 4-day window: today + previous 3 days
  final now = DateTime.now();
  final today = DayKey.normalize(now);
  final firstAllowed = today.subtract(const Duration(days: 3));
  final entryDate = DayKey.normalize(prevEntry.date);

  final isWithinWindow =
      !entryDate.isBefore(firstAllowed) && !entryDate.isAfter(today);

  if (!isWithinWindow) {
    // show error *before* any await → no "use_build_context_synchronously" issue
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
    builder: (_) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: EntryForm(initial: prevEntry),
      );
    },
  );

  if (updatedEntry == null) return;

  // Persist changes to Hive
  try {
    await HiveService.updateEntry(prevEntry, updatedEntry);
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
