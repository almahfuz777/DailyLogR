// lib/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/utils/date_helper.dart';

// Custom exception for entry conflicts (same date)
class JournalEntryConflictException implements Exception {
  final String dateKey;

  const JournalEntryConflictException(this.dateKey);

  @override
  String toString() => 'An entry already exists for $dateKey';
}

class HiveService {
  static const String boxName = 'journal_entries';

  // INIT
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }
    await Hive.openBox<JournalEntry>(boxName);
  }

  static Box<JournalEntry> _box() => Hive.box<JournalEntry>(boxName);


  // ---------- CRUD FUNCTIONS ----------
  
  /// Creates a new entry (unique by date) and persists it to Hive
  static Future<void> createEntry(JournalEntry entry) async {
    final normalizedDate = DayKey.normalize(entry.date);
    final key = DayKey.of(normalizedDate);

    if (_box().containsKey(key)) {
      throw JournalEntryConflictException(key);
    }

    final toStore = entry.copyWith(
      date: normalizedDate,
      updatedAt: DateTime.now(),
    );
    
    await _box().put(key, toStore);
  }

  // Update (existing entry)
  static Future<void> updateEntry(JournalEntry oldEntry, JournalEntry newEntry) async {
    final box = _box();

    final normalizedNewDate = DayKey.normalize(newEntry.date);
    final oldKey = DayKey.of(DayKey.normalize(oldEntry.date));
    final newKey = DayKey.of(normalizedNewDate);

    if (oldKey != newKey && box.containsKey(newKey)) {
      throw JournalEntryConflictException(newKey);
    }

    final toStore = newEntry.copyWith(
      date: normalizedNewDate,
      updatedAt: DateTime.now(),
    );

    if (oldKey != newKey) {
      await box.delete(oldKey);
    }
    await box.put(newKey, toStore);
  }

  // Delete (by date)
  static Future<void> deleteEntry(JournalEntry entry) async {
    final key = DayKey.of(DayKey.normalize(entry.date));
    await _box().delete(key);
  }

  // ---------- Helper ----------

  // Public accessor to the opened box
  static Box<JournalEntry> get journalBox => Hive.box<JournalEntry>(boxName);
}