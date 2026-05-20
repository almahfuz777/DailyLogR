// lib/services/streak_service.dart
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/providers/streak_provider.dart';
import 'package:dailylogr/utils/date_helper.dart';

/// streak calculator
class StreakService {
  const StreakService._();

  /// Derives the current streak state from existing entries.
  ///
  /// A streak is consecutive days ending at today (or yesterday if today has no entry yet). Days inside the edit window with missing entries are treated as recoverable gaps rather than streak-breakers.
  static StreakState calculate(List<JournalEntry> entries) {
    final today = DayKey.normalize(DateTime.now());
    final entryDates = entries
        .map((e) => DayKey.normalize(e.date))
        .where((d) => !d.isAfter(today))
        .toSet();

    if (entryDates.isEmpty) return const StreakState.empty();

    final lastEntryDate = entryDates.reduce(
      (latest, d) => d.isAfter(latest) ? d : latest,
    );

    var currentStreak = 0;
    final missingEditableDates = <DateTime>[];
    DateTime? oldestCompletedDate;

    for (var d = today; ; d = d.subtract(const Duration(days: 1))) {
      if (entryDates.contains(d)) {
        currentStreak++;
        oldestCompletedDate = d;
        continue;
      }
      // Missing day inside the edit window — recoverable, don't break streak.
      if (DayKey.isWithinEditWindow(d)) {
        missingEditableDates.add(d);
        continue;
      }
      break;
    }

    // Only surface recoverable gaps that sit between the oldest completed entry and today — gaps before any entry are irrelevant.
    final relevantGaps = oldestCompletedDate == null
        ? <DateTime>[]
        : missingEditableDates
            .where((d) => !d.isBefore(oldestCompletedDate!))
            .toList();

    return StreakState(
      currentStreak: currentStreak,
      isAtRisk: currentStreak > 0 && relevantGaps.isNotEmpty,
      missingEditableDates: relevantGaps,
      lastEntryDate: lastEntryDate,
    );
  }
}
