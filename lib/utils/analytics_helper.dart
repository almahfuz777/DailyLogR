// lib/utils/analytics_helper.dart
import '../models/journal_entry.dart';
import 'date_helper.dart';

class AnalyticsHelper {
  /// Calculates the average rating (1-5) for a given list of entries.
  static double calculateAverageRating(List<JournalEntry> entries) {
    final ratedEntries = entries.where((e) => e.rating != null).toList();
    if (ratedEntries.isEmpty) return 0.0;

    final sum = ratedEntries.fold(0, (prev, e) => prev + e.rating!);
    return sum / ratedEntries.length;
  }

  /// Returns a map of adjective (mood) frequencies.
  static Map<String, int> getMoodCounts(List<JournalEntry> entries) {
    final Map<String, int> counts = {};
    for (final entry in entries) {
      if (entry.adjective != null && entry.adjective!.isNotEmpty) {
        counts[entry.adjective!] = (counts[entry.adjective!] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Maps each entry's normalized date to its rating.
  static Map<DateTime, double> getRatingTrend(List<JournalEntry> entries) {
    final Map<DateTime, double> trend = {};
    for (final entry in entries) {
      if (entry.rating != null) {
        final date = DayKey.normalize(entry.date);
        trend[date] = entry.rating!.toDouble();
      }
    }
    return trend;
  }

  /// Filters entries by a given time range (e.g., this week, this month).
  static List<JournalEntry> filterEntriesByDateRange(
      List<JournalEntry> entries, DateTime start, DateTime end) {
    final normalizedStart = DayKey.normalize(start);
    final normalizedEnd = DayKey.normalize(end).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // End of day

    return entries.where((e) {
      return e.date.isAfter(normalizedStart.subtract(const Duration(milliseconds: 1))) &&
             e.date.isBefore(normalizedEnd.add(const Duration(milliseconds: 1)));
    }).toList();
  }
}
