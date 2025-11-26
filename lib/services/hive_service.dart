// lib/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/utils/date_helper.dart';

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
  
  /// Create (or Upsert if key exists)
  static Future<void> addEntry(JournalEntry entry) async {
    final normalizedDate = DayKey.normalize(entry.date);
    final key = DayKey.of(normalizedDate);
    
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