// lib/widgets/entry_form.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';

class EntryForm extends StatefulWidget {
  final JournalEntry? initial;
  final DateTime? initialDate;

  const EntryForm({super.key, this.initial, this.initialDate});

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  late DateTime _date;
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _noteFocus = FocusNode();
  String? _adjective;
  int? _rating;

  final List<String> _adjectives = const [
    '😀 Happy',
    '😞 Sad',
    '😌 Calm',
    '🎯 Focused',
    '😪 Tired',
    '😰 Anxious',
    '🤩 Excited',
    '🙏 Grateful',
    '😡 Angry',
    '😕 Confused',
    '😇 Blessed',
    '😐 Meh',
    '😓 Stressed',
    '😴 Sleepy',
    '🤒 Sick',
    '💪 Productive',
    '🏖️ Relaxed',
    '🤔 Thoughtful',
    '🛌 Rested',
    '😃 Joyful',
    '😔 Lonely',
    '😤 Frustrated',
    '😎 Cool',
    '🤗 Loved',
    '❓ Uncertain',
    '😩 Exhausted',
    '🌟 Hopeful',
    '😬 Nervous',
    '🚀 Enthusiastic',
  ];

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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

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

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.75,
          expand: false,
          builder: (ctx, scrollController) {
            final color = Theme.of(ctx).colorScheme;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 16),
                  Text(
                    'How was your day?',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _adjectives.map((adj) {
                          final selected = _adjective == adj;
                          return ChoiceChip(
                            label: Text(adj),
                            selected: selected,
                            onSelected: (_) {
                              setState(
                                () => _adjective = selected ? null : adj,
                              );
                              Navigator.pop(ctx);
                            },
                            showCheckmark: false,
                            selectedColor: color.primaryContainer,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRatingPicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final color = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rate your day',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      final filled = (_rating ?? 0) >= idx;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _rating = idx);
                          setSheetState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 40,
                            color: filled ? Colors.amber : color.outlineVariant,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (_rating != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _rating = null);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear rating'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Top bar
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainer,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Discard',
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save'),
              ),
            ],
          ),
        ),

        // Content area — note field fills remaining height and scrolls internally
        Expanded(
          child: GestureDetector(
            onTap: () => _noteFocus.requestFocus(),
            behavior: HitTestBehavior.translucent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        color: color.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      focusNode: _noteFocus,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Note',
                        hintStyle: TextStyle(
                          color: color.onSurfaceVariant.withValues(alpha: 0.65),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom toolbar — enlarged and pinned to bottom
        Container(
          decoration: BoxDecoration(
            color: color.surfaceContainer,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Date
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: color.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DayKey.ofShort(_date),
                            style: TextStyle(
                              fontSize: 14,
                              color: color.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Mood
                  InkWell(
                    onTap: _showMoodPicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        _adjective ?? '😊 Mood',
                        style: TextStyle(
                          fontSize: 14,
                          color: _adjective != null
                              ? color.onSurface
                              : color.onSurfaceVariant,
                          fontWeight: _adjective != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Rating stars
                  InkWell(
                    onTap: _showRatingPicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          final filled = (_rating ?? 0) >= i + 1;
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 22,
                            color: filled ? Colors.amber : color.outlineVariant,
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
