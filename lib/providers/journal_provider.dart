import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry.dart';
import '../services/hive_service.dart';

class JournalNotifier extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() {
    // Initial fetch from Hive
    return _fetchSortedEntries();
  }

  List<JournalEntry> _fetchSortedEntries() {
    final entries = HiveService.journalBox.values.toList();
    // Sort descending by date (newest first)
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// Refreshes the internal state to match the Hive box
  void _reload() {
    state = _fetchSortedEntries();
  }

  /// Creates a new entry in Hive and updates state
  Future<void> createEntry(JournalEntry entry) async {
    await HiveService.createEntry(entry);
    _reload();
  }

  /// Updates an existing entry in Hive and updates state
  Future<void> updateEntry(JournalEntry oldEntry, JournalEntry newEntry) async {
    await HiveService.updateEntry(oldEntry, newEntry);
    _reload();
  }

  /// Deletes an entry from Hive and updates state
  Future<void> deleteEntry(JournalEntry entry) async {
    await HiveService.deleteEntry(entry);
    _reload();
  }
}

final journalProvider = NotifierProvider<JournalNotifier, List<JournalEntry>>(() {
  return JournalNotifier();
});
