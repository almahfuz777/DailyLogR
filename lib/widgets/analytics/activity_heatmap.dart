// lib/widgets/activity_heatmap.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/journal_entry.dart';
import '../../utils/date_helper.dart';

class ActivityHeatmap extends StatelessWidget {
  final List<JournalEntry> entries;

  const ActivityHeatmap({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    
    final entryDates = entries.map((e) => DayKey.normalize(e.date)).toSet();
    
    // Setup current month data
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    // weekday returns 1 for Monday, 7 for Sunday. 
    // We want Sunday = 0, Monday = 1, etc., so we do % 7.
    final firstDayOffset = firstDayOfMonth.weekday % 7; 

    final monthYearFormat = DateFormat('MMMM yyyy');
    final List<String> weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistency',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                monthYearFormat.format(now),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekdays Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return Text(
                day,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 days a week
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              mainAxisExtent: 32, // Forces a compact fixed height for each cell
            ),
            // total items = empty slots before 1st + number of days in month
            itemCount: firstDayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink(); // Empty slot for offset
              }

              final dayNumber = index - firstDayOffset + 1;
              final date = DateTime(now.year, now.month, dayNumber);
              final normalizedDate = DayKey.normalize(date);
              
              final hasEntry = entryDates.contains(normalizedDate);
              final isToday = DayKey.normalize(now).isAtSameMomentAs(normalizedDate);

              return Tooltip(
                message: DateFormat('MMM d, yyyy').format(date),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasEntry 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !hasEntry
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Text(
                    '$dayNumber',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasEntry 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurface,
                      fontWeight: hasEntry || isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),

          // Simple Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem(
                context, 
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), 
                'No entry'
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                context, 
                theme.colorScheme.primary, 
                'Logged'
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label, 
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant
          ),
        ),
      ],
    );
  }
}
