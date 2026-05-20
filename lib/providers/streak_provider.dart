// lib/providers/streak_provider.dart
import 'package:dailylogr/providers/journal_provider.dart';
import 'package:dailylogr/services/streak_service.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Derived state for the journal streak.
class StreakState {
  final int currentStreak;
  final bool isAtRisk;
  final List<DateTime> missingEditableDates;
  final DateTime? lastEntryDate;

  const StreakState({
    required this.currentStreak,
    required this.isAtRisk,
    required this.missingEditableDates,
    required this.lastEntryDate,
  });

  const StreakState.empty()
      : currentStreak = 0,
        isAtRisk = false,
        missingEditableDates = const [],
        lastEntryDate = null;

  /// The nearest missing editable day that can still recover the streak.
  DateTime? get nextRecoverableDate {
    if (missingEditableDates.isEmpty) return null;
    return ([...missingEditableDates]..sort()).last;
  }

  /// User-facing helper text shown below the streak count when at risk.
  String? get recoveryHint {
    final date = nextRecoverableDate;
    if (!isAtRisk || date == null) return null;

    final today = DayKey.normalize(DateTime.now());
    if (date == today) return 'Log today to keep your streak';
    if (date == today.subtract(const Duration(days: 1))) {
      return 'Log yesterday to keep your streak';
    }
    return 'Log ${DayKey.ofShort(date)} to keep your streak';
  }
}

/// Derived streak state from journal entries — recomputed whenever the journal changes.
final streakProvider = Provider<StreakState>((ref) {
  final entries = ref.watch(journalProvider);
  return StreakService.calculate(entries);
});
