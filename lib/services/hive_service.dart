import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailylogr/models/journal_entry.dart';

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
    // Use date (YYYY-MM-DD) as unique key so only 1 entry per day
    final key = _dayKey(entry.date);
    await _box().put(key, entry);
  }

  // /// Read (by date)
  // static JournalEntry? getEntryByDate(DateTime date) {
  //   final key = _dayKey(date);
  //   return _box().get(key);
  // }

  // /// Read all
  // static List<JournalEntry> getAllEntries() {
  //   return _box().values.toList();
  // }

  // /// Update (just re-put with same key)
  // static Future<void> updateEntry(JournalEntry entry) async {
  //   final key = _dayKey(entry.date);
  //   entry.updatedAt = DateTime.now(); // refresh timestamp
  //   await _box().put(key, entry);
  // }

  // /// Delete (by date)
  // static Future<void> deleteEntryByDate(DateTime date) async {
  //   final key = _dayKey(date);
  //   await _box().delete(key);
  // }

  // ---------- Helper ----------

  /// Normalize a DateTime into a YYYY-MM-DD string
  static String _dayKey(DateTime d) => 
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Public accessor to the opened box
  static Box<JournalEntry> get journalBox => Hive.box<JournalEntry>(boxName);
}