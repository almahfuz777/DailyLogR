import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journal_entry.dart';
import '../services/hive_service.dart';
import '../services/sync_service.dart';
import '../utils/date_helper.dart';

class JournalNotifier extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() {
    // Schedule trash purge as a deferred microtask so build() stays synchronous to avoid ANRs on slower devices
    Future.microtask(_purgeOldTrash);
    return _fetchSortedEntries();
  }

  void _purgeOldTrash() {
    final entries = HiveService.journalBox.values.toList();
    final now = DateTime.now();
    for (var entry in entries) {
      if (entry.isDeleted && entry.deletedAt != null) {
        if (now.difference(entry.deletedAt!).inDays >= 30) {
          HiveService.permanentlyDeleteEntry(entry);
        }
      }
    }
  }

  List<JournalEntry> _fetchSortedEntries() {
    final entries = HiveService.journalBox.values
        .where((e) => !e.isDeleted)
        .toList();
    // Sort descending by date (newest first)
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  List<JournalEntry> getDeletedEntries() {
    final entries = HiveService.journalBox.values
        .where((e) => e.isDeleted)
        .toList();
    // Sort descending by deletedAt
    entries.sort((a, b) => (b.deletedAt ?? b.date).compareTo(a.deletedAt ?? a.date));
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

  /// Soft Deletes an entry from Hive and updates state
  Future<void> deleteEntry(JournalEntry entry) async {
    await HiveService.deleteEntry(entry);
    _reload();
  }

  /// Restores a soft-deleted entry
  Future<void> restoreEntry(JournalEntry entry) async {
    final restored = entry.copyWith(
       isDeleted: false, 
       deletedAt: null, 
       updatedAt: DateTime.now(),
    );
    // Overwrite the Hive box directly to bypass the oldKey logic in updateEntry
    await HiveService.journalBox.put(DayKey.of(DayKey.normalize(restored.date)), restored);
    SyncService.pushEntry(restored);
    _reload();
  }

  /// Permanently deletes an entry
  Future<void> permanentlyDeleteEntry(JournalEntry entry) async {
    await HiveService.permanentlyDeleteEntry(entry);
    _reload();
  }
}

final journalProvider = NotifierProvider<JournalNotifier, List<JournalEntry>>(() {
  return JournalNotifier();
});
