import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/streak_provider.dart';
import '../utils/date_helper.dart';

class WidgetService {
  const WidgetService._();

  static const String _widgetName = 'TodayWidgetProvider';

  /// Updates the home screen widget using the current entries and streak state.
  static Future<void> updateWidget({
    required List<JournalEntry> entries,
    required StreakState streak,
  }) async {
    final today = DayKey.normalize(DateTime.now());
    final todayKey = DayKey.of(today);
    
    // Find today's entry
    JournalEntry? todayEntry;
    for (final entry in entries) {
      if (DayKey.of(DayKey.normalize(entry.date)) == todayKey) {
        todayEntry = entry;
        break;
      }
    }

    final hasEntry = todayEntry != null;

    // Save basic widget flags and data
    await HomeWidget.saveWidgetData<bool>('has_entry', hasEntry);
    await HomeWidget.saveWidgetData<String>('date_text', DayKey.ofLong(today));
    await HomeWidget.saveWidgetData<int>('streak_count', streak.currentStreak);

    if (hasEntry) {
      await HomeWidget.saveWidgetData<String>('entry_title', todayEntry.title ?? '');
      await HomeWidget.saveWidgetData<String>('entry_note', todayEntry.note);
      await HomeWidget.saveWidgetData<String>('entry_adjective', todayEntry.adjective ?? '');
      await HomeWidget.saveWidgetData<int>('entry_rating', todayEntry.rating ?? 0);
      await HomeWidget.saveWidgetData<int>('entry_color', todayEntry.entryColor ?? 0);
    } else {
      await HomeWidget.saveWidgetData<String>('entry_title', '');
      await HomeWidget.saveWidgetData<String>('entry_note', '');
      await HomeWidget.saveWidgetData<String>('entry_adjective', '');
      await HomeWidget.saveWidgetData<int>('entry_rating', 0);
      await HomeWidget.saveWidgetData<int>('entry_color', 0);
    }

    // Trigger update on Android & iOS platforms
    await HomeWidget.updateWidget(
      name: _widgetName,
      androidName: _widgetName,
      iOSName: _widgetName,
    );
  }
}

/// Riverpod provider to automatically update the home widget whenever journal entries or streak changes.
final widgetUpdaterProvider = Provider<void>((ref) {
  final entries = ref.watch(journalProvider);
  final streak = ref.watch(streakProvider);

  // Perform async update to prevent blocking UI main thread
  Future.microtask(() => WidgetService.updateWidget(
        entries: entries,
        streak: streak,
      ));
});
