// lib/widgets/entry_form.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/widgets/entry_form/mood_picker_sheet.dart';
import 'package:dailylogr/widgets/entry_form/rating_picker_sheet.dart';
import 'package:dailylogr/widgets/entry_form/entry_top_bar.dart';
import 'package:dailylogr/widgets/entry_form/entry_content_area.dart';
import 'package:dailylogr/widgets/entry_form/entry_bottom_toolbar.dart';

class EntryForm extends ConsumerStatefulWidget {
  final JournalEntry? initial;
  final DateTime? initialDate;
  final VoidCallback? onDelete;
  final bool readOnly;

  const EntryForm({
    super.key,
    this.initial,
    this.initialDate,
    this.onDelete,
    this.readOnly = false,
  });

  @override
  ConsumerState<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends ConsumerState<EntryForm> {
  late DateTime _date;
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _noteFocus = FocusNode();
  String? _adjective;
  int? _rating;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _date = DayKey.normalize(e?.date ?? widget.initialDate ?? DateTime.now());
    _titleCtrl.text = e?.title ?? '';
    _noteCtrl.text = e?.note ?? '';
    _adjective = e?.adjective;
    _rating = e?.rating;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  // Show snackbar
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // Pick date for entry 
  Future<void> _pickDate() async {
    final today = DayKey.normalize(DateTime.now());
    final firstAllowed = DayKey.editWindowStart;
    final initialDate = DayKey.isWithinEditWindow(_date) ? _date : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowed,
      lastDate: today,
      selectableDayPredicate: DayKey.isWithinEditWindow,
    );

    if (picked != null) {
      setState(() => _date = DayKey.normalize(picked));
    }
  }

  // Save entry
  Future<void> _save() async {
    final note = _noteCtrl.text.trim();

    if (note.isEmpty) {
      _showSnack("Note can't be empty");
      return;
    }

    final entry = JournalEntry(
      id:
          widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      date: _date,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      note: note,
      adjective: (_adjective != null && _adjective!.trim().isNotEmpty)
          ? _adjective
          : null,
      rating: _rating,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, entry);
  }

  // Confirm delete entry
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final color = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Delete entry?'),
          content: const Text(
            'Are you sure you want to delete this journal entry?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: color.error,
                foregroundColor: color.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      widget.onDelete?.call();
    }
  }

  // Show mood picker sheet
  Future<void> _showMoodPicker() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MoodPickerSheet(initialMood: _adjective),
    );

    if (result != null && mounted) {
      setState(() => _adjective = result.isEmpty ? null : result);
    }
  }

  // Show rating picker sheet
  Future<void> _showRatingPicker() async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RatingPickerSheet(initialRating: _rating),
    );

    if (result != null && mounted) {
      setState(() {
        _rating = result == -1 ? null : result;
      });
    }
  }

  // Build Entry Form UI
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Bar for Entry Form
        EntryTopBar(
          readOnly: widget.readOnly,
          onBack: () => Navigator.pop(context),
          onSave: _save,
        ),

        // Content Area for Entry Form
        EntryContentArea(
          titleCtrl: _titleCtrl,
          noteCtrl: _noteCtrl,
          noteFocus: _noteFocus,
          readOnly: widget.readOnly,
        ),

        // Bottom Toolbar for Entry Form
        EntryBottomToolbar(
          date: _date,
          adjective: _adjective,
          rating: _rating,
          readOnly: widget.readOnly,
          showDeleteOption: widget.initial != null,
          updatedAt: widget.initial?.updatedAt,
          onPickDate: _pickDate,
          onShowMoodPicker: _showMoodPicker,
          onShowRatingPicker: _showRatingPicker,
          onDelete: _confirmDelete,
        ),
      ],
    );
  }
}
