// lib/widgets/activity_calendar_strip.dart
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';

/// Compact, horizontally scrollable single-row activity calendar.
///
/// Shows one date box per day from [_historyDays] ago to today.
/// Green-filled boxes indicate a journal entry exists on that date.
/// The month/year label updates based on the center-visible date.
class ActivityCalendarStrip extends StatefulWidget {
  final List<JournalEntry> entries;
  final void Function(DateTime)? onDateTapped;
  final DateTime selectedDate;

  const ActivityCalendarStrip({
    super.key,
    required this.entries,
    required this.selectedDate,
    this.onDateTapped,
  });

  @override
  State<ActivityCalendarStrip> createState() => _ActivityCalendarStripState();
}

class _ActivityCalendarStripState extends State<ActivityCalendarStrip> {
  static const int _historyDays = 90;
  static const double _boxSize = 44.0;
  static const double _boxSpacing = 6.0;

  late final ScrollController _scrollController;
  late final DateTime _today;
  late final List<DateTime> _dates;
  late Set<String> _entryKeys;

  /// The month/year label derived from the center-visible date.
  late String _visibleLabel;

  @override
  void initState() {
    super.initState();
    _today = DayKey.normalize(DateTime.now());
    _dates = List.generate(
      _historyDays + 1, // today + 90 past days
      (i) => _today.subtract(Duration(days: i)),
    );
    _entryKeys = _buildEntryKeys(widget.entries);
    _scrollController = ScrollController()..addListener(_onScroll);
    _visibleLabel = _formatLabel(_today);
  }

  @override
  void didUpdateWidget(covariant ActivityCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries != oldWidget.entries) {
      setState(() => _entryKeys = _buildEntryKeys(widget.entries));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Set<String> _buildEntryKeys(List<JournalEntry> entries) =>
      entries.map((e) => DayKey.of(DayKey.normalize(e.date))).toSet();

  String _formatLabel(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]}, ${d.year}';
  }

  void _onScroll() {
    final viewportWidth = _scrollController.position.viewportDimension;
    final centerOffset = _scrollController.offset + viewportWidth / 2;
    final centerIndex =
        (centerOffset / (_boxSize + _boxSpacing)).floor().clamp(0, _dates.length - 1);
    final label = _formatLabel(_dates[centerIndex]);
    if (label != _visibleLabel) {
      setState(() => _visibleLabel = label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: color.secondaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.secondary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month/Year label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _visibleLabel,
              key: ValueKey(_visibleLabel),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable date strip
          SizedBox(
            height: _boxSize + 4,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: _dates.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: _boxSpacing),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final key = DayKey.of(date);
                final hasEntry = _entryKeys.contains(key);
                final isSelected = date == widget.selectedDate;

                return GestureDetector(
                  onTap: () => widget.onDateTapped?.call(date),
                  child: _DateBox(
                    day: date.day,
                    hasEntry: hasEntry,
                    isSelected: isSelected,
                    size: _boxSize,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final int day;
  final bool hasEntry;
  final bool isSelected;
  final double size;

  const _DateBox({
    required this.day,
    required this.hasEntry,
    required this.isSelected,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    final fillColor = hasEntry
        ? Colors.green.withValues(alpha: 0.55)
        : color.surfaceContainerHighest.withValues(alpha: 0.5);

    final borderColor = isSelected
        ? color.primary
        : hasEntry
            ? Colors.green.withValues(alpha: 0.7)
            : color.outlineVariant.withValues(alpha: 0.5);

    final borderWidth = isSelected ? 2.0 : 1.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Text(
        '$day',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: hasEntry
              ? Colors.green.shade900
              : color.onSurfaceVariant,
        ),
      ),
    );
  }
}
