// lib/widgets/entry_editor.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart'; 

class EntryEditor extends StatefulWidget {
  final JournalEntry? initial;
  const EntryEditor({super.key, this.initial});

  @override
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  late DateTime _date;
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _adjective;
  int? _rating;

  // emoji + adjective options
  final List<String> _adjectives = const [
    '😀 Happy','😞 Sad','😌 Calm','🎯 Focused','😴 Tired','😬 Anxious','🤩 Excited','🙏 Grateful',
    '😡 Angry','😕 Confused','😇 Blessed','😐 Meh','😓 Stressed','😴 Sleepy','🤒 Sick','💪 Productive',
    '🏖️ Relaxed','🤔 Thoughtful','😴 Rested','😃 Joyful','😔 Lonely','😤 Frustrated','😎 Cool','🤗 Loved',
    '😕 Uncertain','😴 Exhausted','😇 Hopeful','😬 Nervous','🤩 Enthusiastic',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _date = DayKey.normalize(e?.date ?? DateTime.now());
    _titleCtrl.text = e?.title ?? '';
    _noteCtrl.text = e?.note ?? '';
    _adjective = e?.adjective;
    _rating = e?.rating;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final firstAllowed = today.subtract(const Duration(days: 4)); // today+last 3 days
    final lastAllowed  = today;                                   // today

    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(firstAllowed) || _date.isAfter(lastAllowed) ? today : _date,
      firstDate: firstAllowed,
      lastDate: lastAllowed,

      selectableDayPredicate: (day){
        final d = DayKey.normalize(day);
        return !d.isBefore(firstAllowed) && !d.isAfter(lastAllowed);
      }
    );

    if (picked != null) {
      setState(() => _date = DayKey.normalize(picked));
    }
  }

  Future<void> _save() async { // 👈 now async
    final note = _noteCtrl.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note can’t be empty'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        )
      );
      return;
    }

    // Duplicate-by-date guard
    final box = HiveService.journalBox;
    final newKey = DayKey.of(_date);

    if (widget.initial == null) {
      // Creating a new entry: block if key exists
      if (box.containsKey(newKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An entry already exists for $newKey'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(12),
          ),
        );
        return;
      }
    } else {
      // Editing: allow same date, but block if changing to an occupied date
      final originalKey = DayKey.of(DayKey.normalize(widget.initial!.date));
      final changingDateToAnotherDay = newKey != originalKey;
      if (changingDateToAnotherDay && box.containsKey(newKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An entry already exists for $newKey'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(12),
          ),
        );
        return;
      }
    }

    final entry = JournalEntry(
      id: widget.initial?.id ??
        DateTime.now().microsecondsSinceEpoch.toString(),
      date: _date,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      note: note,
      adjective: (_adjective != null && _adjective!.trim().isNotEmpty) ? _adjective : null,
      rating: _rating,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.initial == null ? 'New Entry' : 'Edit Entry',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Text(
                  DayKey.of(_date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Pick date'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: _noteCtrl,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Adjective + Rating (responsive, no overflow)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;

                final adjectiveField = DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _adjective != null && _adjectives.contains(_adjective) ? _adjective : null,
                    items: _adjectives
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(a, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _adjective = v),
                    decoration: const InputDecoration(
                      labelText: 'Day adjective',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),

                );

                final ratingField = InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Rating',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(5, (i) {
                        final idx = i + 1;
                        final filled = (_rating ?? 0) >= idx;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = idx),
                          child: Icon(filled ? Icons.star : Icons.star_border, size: 20),
                        );
                      }),
                    ),

                );

                if (isNarrow) {
                  return Column(
                    children: [
                      adjectiveField,
                      const SizedBox(height: 12),
                      ratingField,
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(child: adjectiveField),
                      const SizedBox(width: 12),
                      Expanded(child: ratingField),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // Save
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
