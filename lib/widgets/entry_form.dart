// lib/widgets/entry_form.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/widgets/entry_form/mood_picker_sheet.dart';
import 'package:dailylogr/widgets/entry_form/rating_picker_sheet.dart';
import 'package:dailylogr/widgets/entry_form/color_picker_sheet.dart';
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
  final _titleUndoCtrl = UndoHistoryController();
  final _noteUndoCtrl = UndoHistoryController();
  String? _adjective;
  int? _rating;
  int? _entryColor;
  bool _canUndo = false;
  bool _canRedo = false;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _date = DayKey.normalize(e?.date ?? widget.initialDate ?? DateTime.now());
    _titleCtrl.text = e?.title ?? '';
    _noteCtrl.text = e?.note ?? '';
    _adjective = e?.adjective;
    _rating = e?.rating;
    _entryColor = e?.entryColor;

    // Listen for undo/redo state changes
    _titleUndoCtrl.addListener(_syncUndoState);
    _noteUndoCtrl.addListener(_syncUndoState);
  }

  @override
  void dispose() {
    _titleUndoCtrl.removeListener(_syncUndoState);
    _noteUndoCtrl.removeListener(_syncUndoState);
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _noteFocus.dispose();
    _titleUndoCtrl.dispose();
    _noteUndoCtrl.dispose();
    super.dispose();
  }

  // Sync undo/redo button states from both controllers
  void _syncUndoState() {
    setState(() {
      _canUndo = _titleUndoCtrl.value.canUndo || _noteUndoCtrl.value.canUndo;
      _canRedo = _titleUndoCtrl.value.canRedo || _noteUndoCtrl.value.canRedo;
    });
  }

  /// Inserts a prefix at the start of the current cursor line.
  void _insertLinePrefix(String prefix) {
    final text = _noteCtrl.text;
    var selection = _noteCtrl.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: text.length);
      _noteCtrl.selection = selection;
    }

    final cursorPos = selection.baseOffset;
    final lineStart = cursorPos == 0 ? 0 : text.lastIndexOf('\n', cursorPos - 1) + 1;

    // Check if prefix already exists at line start — toggle it off
    if (text.substring(lineStart).startsWith(prefix)) {
      final newText = text.replaceRange(lineStart, lineStart + prefix.length, '');
      final newCursorPos = (cursorPos - prefix.length).clamp(lineStart, newText.length);
      _noteCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
      _noteFocus.requestFocus();
      return;
    }

    // Remove existing bullet prefix before inserting new one
    String cleanText = text;
    int offsetAdjust = 0;
    if (cleanText.substring(lineStart).startsWith('- ')) {
      cleanText = cleanText.replaceRange(lineStart, lineStart + 2, '');
      offsetAdjust = -2;
    }

    // Also strip numbered list prefix (e.g., "1. ", "12. ")
    final numberedMatch = RegExp(r'^\d+\.\s').firstMatch(cleanText.substring(lineStart));
    if (numberedMatch != null && offsetAdjust == 0) {
      cleanText = cleanText.replaceRange(lineStart, lineStart + numberedMatch.end, '');
      offsetAdjust = -numberedMatch.end;
    }

    final newText = cleanText.replaceRange(lineStart, lineStart, prefix);
    final newCursorPos = (cursorPos + offsetAdjust + prefix.length).clamp(0, newText.length);
    _noteCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newCursorPos,
      ),
    );
    _noteFocus.requestFocus();
  }

  /// Inserts a numbered list prefix, auto-detecting the next number.
  void _insertNumberedList() {
    final text = _noteCtrl.text;
    var selection = _noteCtrl.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: text.length);
      _noteCtrl.selection = selection;
    }

    final cursorPos = selection.baseOffset;
    final lineStart = cursorPos == 0 ? 0 : text.lastIndexOf('\n', cursorPos - 1) + 1;

    // Check if current line already has a numbered prefix — toggle off
    final existing = RegExp(r'^\d+\.\s').firstMatch(text.substring(lineStart));
    if (existing != null) {
      final newText = text.replaceRange(lineStart, lineStart + existing.end, '');
      final newCursorPos = (cursorPos - existing.end).clamp(lineStart, newText.length);
      _noteCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
      _noteFocus.requestFocus();
      return;
    }

    // Find previous line's number to auto-increment
    int nextNum = 1;
    if (lineStart > 0) {
      final prevLineEnd = lineStart - 1;
      final prevLineStart = text.lastIndexOf('\n', prevLineEnd - 1) + 1;
      final prevLine = text.substring(prevLineStart, prevLineEnd);
      final prevMatch = RegExp(r'^(\d+)\.\s').firstMatch(prevLine);
      if (prevMatch != null) {
        nextNum = int.parse(prevMatch.group(1)!) + 1;
      }
    }

    // Remove existing bullet prefix
    String cleanText = text;
    int offsetAdjust = 0;
    if (cleanText.substring(lineStart).startsWith('- ')) {
      cleanText = cleanText.replaceRange(lineStart, lineStart + 2, '');
      offsetAdjust = -2;
    }

    final prefix = '$nextNum. ';
    final newText = cleanText.replaceRange(lineStart, lineStart, prefix);
    final newCursorPos = (cursorPos + offsetAdjust + prefix.length).clamp(0, newText.length);
    _noteCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newCursorPos,
      ),
    );
    _noteFocus.requestFocus();
  }

  // Trigger undo on the controller that supports it
  void _undo() {
    if (_noteUndoCtrl.value.canUndo) {
      _noteUndoCtrl.undo();
    } else if (_titleUndoCtrl.value.canUndo) {
      _titleUndoCtrl.undo();
    }
  }

  // Trigger redo on the controller that supports it
  void _redo() {
    if (_noteUndoCtrl.value.canRedo) {
      _noteUndoCtrl.redo();
    } else if (_titleUndoCtrl.value.canRedo) {
      _titleUndoCtrl.redo();
    }
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
      entryColor: _entryColor,
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

  // Show color picker sheet
  Future<void> _showColorPicker() async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ColorPickerSheet(selectedColor: _entryColor),
    );

    if (mounted) {
      setState(() => _entryColor = result);
    }
  }

  // Build Entry Form UI
  @override
  Widget build(BuildContext context) {
    final bgColor = _entryColor != null ? Color(_entryColor!) : null;

    return Column(
      children: [
        // Top Bar for Entry Form
        EntryTopBar(
          readOnly: widget.readOnly,
          canUndo: _canUndo,
          canRedo: _canRedo,
          onBack: () => Navigator.pop(context),
          onSave: _save,
          onUndo: _undo,
          onRedo: _redo,
          onBulletList: () => _insertLinePrefix('- '),
          onNumberedList: _insertNumberedList,
        ),

        // Content Area for Entry Form
        EntryContentArea(
          titleCtrl: _titleCtrl,
          noteCtrl: _noteCtrl,
          noteFocus: _noteFocus,
          readOnly: widget.readOnly,
          titleUndoController: _titleUndoCtrl,
          noteUndoController: _noteUndoCtrl,
          backgroundColor: bgColor,
        ),

        // Bottom Toolbar for Entry Form
        EntryBottomToolbar(
          date: _date,
          adjective: _adjective,
          rating: _rating,
          readOnly: widget.readOnly,
          showDeleteOption: widget.initial != null,
          updatedAt: widget.initial?.updatedAt,
          entryColor: _entryColor,
          onPickDate: _pickDate,
          onShowMoodPicker: _showMoodPicker,
          onShowRatingPicker: _showRatingPicker,
          onShowColorPicker: _showColorPicker,
          onDelete: _confirmDelete,
        ),
      ],
    );
  }
}
