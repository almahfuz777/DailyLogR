// lib/widgets/entry_editor_sheet.dart
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/entry_form.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/journal_provider.dart';

/// Opens the entry bottom sheet for both **creating** and **editing**.
Future<void> entryEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  JournalEntry? initial,
  DateTime? initialDate,
}) async {
  final isEdit = initial != null;
  final normalizedInitialDate = initialDate == null
      ? null
      : DayKey.normalize(initialDate);

  // If editing an entry outside the edit window, open in readOnly mode.
  final isReadOnly = isEdit && !DayKey.isWithinEditWindow(initial.date);

  // Guard: enforce the 4-day edit window for CREATING new entries.
  if (!isEdit &&
      normalizedInitialDate != null &&
      !DayKey.isWithinEditWindow(normalizedInitialDate)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You can only create entries within the editable window.',
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(12),
      ),
    );
    return;
  }

  // If opening in read-only mode, optionally show a toast to inform the user
  if (isReadOnly) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing in read-only mode (older than 4 days).'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 2),
      ),
    );
  }

  final updatedEntry = await showModalBottomSheet<JournalEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Scaffold(
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      body: EntryForm(
        initial: initial,
        initialDate: normalizedInitialDate,
        readOnly: isReadOnly,
        onDelete: () {
          if (initial != null) {
            ref.read(journalProvider.notifier).deleteEntry(initial);
          }
          Navigator.pop(ctx); // Close the sheet modal immediately!
        },
      ),
    ),
  );

  if (updatedEntry == null) return;

  // Persist changes via provider
  try {
    if (isEdit) {
      await ref
          .read(journalProvider.notifier)
          .updateEntry(initial, updatedEntry);
    } else {
      await ref.read(journalProvider.notifier).createEntry(updatedEntry);
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
