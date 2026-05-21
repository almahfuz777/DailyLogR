// lib/services/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/services/sync_service.dart';
import 'package:dailylogr/services/notification_service.dart';

// Custom exception for entry conflicts (same date)
class JournalEntryConflictException implements Exception {
  final String dateKey;

  const JournalEntryConflictException(this.dateKey);

  @override
  String toString() => 'An entry already exists for $dateKey';
}

class HiveService {
  static const String _anonymousBoxName = 'journal_entries';

  /// The currently active box name, keyed by UID when authenticated.
  static String _activeBoxName = _anonymousBoxName;

  // INIT — opens the anonymous (default) box at app startup.
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }
    await Hive.openBox<JournalEntry>(_anonymousBoxName);
  }

  /// Switches the active Hive box when a user logs in or out.
  /// - **Login** ([uid] non-null): opens the user-specific box.
  /// - **Logout** ([uid] null): wipes the user-specific box from disk
  static Future<void> switchUser(String? uid) async {
    final targetBoxName = uid != null ? 'journal_entries_$uid' : _anonymousBoxName;

    // Already on the correct box — nothing to do.
    if (targetBoxName == _activeBoxName) return;

    final previousBoxName = _activeBoxName;

    // Open the target box if not already open.
    if (!Hive.isBoxOpen(targetBoxName)) {
      await Hive.openBox<JournalEntry>(targetBoxName);
    }

    _activeBoxName = targetBoxName;

    // On logout: wipe the authenticated user's box from disk.
    if (uid == null && previousBoxName != _anonymousBoxName) {
      if (Hive.isBoxOpen(previousBoxName)) {
        final box = Hive.box<JournalEntry>(previousBoxName);
        await box.deleteFromDisk();
      }
    }
  }

  /// Whether the anonymous box has entries waiting to be migrated.
  static bool get hasAnonymousEntries {
    if (!Hive.isBoxOpen(_anonymousBoxName)) return false;
    return Hive.box<JournalEntry>(_anonymousBoxName).isNotEmpty;
  }

  /// Number of entries in the anonymous box.
  static int get anonymousEntryCount {
    if (!Hive.isBoxOpen(_anonymousBoxName)) return 0;
    return Hive.box<JournalEntry>(_anonymousBoxName).length;
  }

  /// Merges anonymous entries into the current user's box (last-write-wins) and pushes each to Firestore for cloud sync.
  static Future<void> migrateAnonymousEntries() async {
    final anonBox = Hive.box<JournalEntry>(_anonymousBoxName);
    if (anonBox.isEmpty) return;

    final userBox = _box();

    for (final key in anonBox.keys.toList()) {
      final anonEntry = anonBox.get(key);
      if (anonEntry == null) continue;

      final existing = userBox.get(key);
      if (existing == null || anonEntry.updatedAt.isAfter(existing.updatedAt)) {
        await userBox.put(key, anonEntry);
        SyncService.pushEntry(anonEntry);
      }
    }

    await anonBox.clear();
  }

  /// Discards all anonymous entries without merging.
  static Future<void> discardAnonymousEntries() async {
    if (!Hive.isBoxOpen(_anonymousBoxName)) return;
    await Hive.box<JournalEntry>(_anonymousBoxName).clear();
  }

  static Box<JournalEntry> _box() => Hive.box<JournalEntry>(_activeBoxName);


  // ---------- CRUD FUNCTIONS ----------
  
  /// Creates a new entry (unique by date) and persists it to Hive
  static Future<void> createEntry(JournalEntry entry) async {
    final normalizedDate = DayKey.normalize(entry.date);
    final key = DayKey.of(normalizedDate);

    if (_box().containsKey(key)) {
      final existing = _box().get(key);
      if (existing != null && !existing.isDeleted) {
        throw JournalEntryConflictException(key);
      }
    }

    final toStore = entry.copyWith(
      date: normalizedDate,
      updatedAt: DateTime.now(),
    );
    
    await _box().put(key, toStore);
    // Sync to Cloud
    SyncService.pushEntry(toStore);
    _checkAndCancelNotifications(toStore.date);
  }

  // Update (existing entry)
  static Future<void> updateEntry(JournalEntry oldEntry, JournalEntry newEntry) async {
    final box = _box();

    final normalizedNewDate = DayKey.normalize(newEntry.date);
    final oldKey = DayKey.of(DayKey.normalize(oldEntry.date));
    final newKey = DayKey.of(normalizedNewDate);

    if (oldKey != newKey && box.containsKey(newKey)) {
      final existing = box.get(newKey);
      if (existing != null && !existing.isDeleted) {
        throw JournalEntryConflictException(newKey);
      }
    }

    final toStore = newEntry.copyWith(
      date: normalizedNewDate,
      updatedAt: DateTime.now(),
    );

    if (oldKey != newKey) {
      await box.delete(oldKey);
      // Soft delete the old entry in cloud since the date key changed
      final deletedOld = oldEntry.copyWith(isDeleted: true, deletedAt: DateTime.now());
      SyncService.pushEntry(deletedOld);
    }
    await box.put(newKey, toStore);
    SyncService.pushEntry(toStore);
    _checkAndCancelNotifications(toStore.date);
  }

  // Soft Delete
  static Future<void> deleteEntry(JournalEntry entry) async {
    final key = DayKey.of(DayKey.normalize(entry.date));
    
    final toStore = entry.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _box().put(key, toStore); // Keep in Hive, just marked as deleted
    SyncService.pushEntry(toStore);
  }
  
  // Permanent Delete
  static Future<void> permanentlyDeleteEntry(JournalEntry entry) async {
    final key = DayKey.of(DayKey.normalize(entry.date));
    await _box().delete(key);
    SyncService.permanentlyDeleteEntry(entry);
  }

  // ---------- Helper ----------

  // Public accessor to the opened box
  static Box<JournalEntry> get journalBox => Hive.box<JournalEntry>(_activeBoxName);

  static void _checkAndCancelNotifications(DateTime entryDate) {
    final now = DateTime.now();
    final isToday = entryDate.year == now.year &&
        entryDate.month == now.month &&
        entryDate.day == now.day;
    
    if (isToday) {
      NotificationService().cancelRemindersForToday();
    }
    
    final isClosingDay = DayKey.normalize(entryDate) == DayKey.normalize(now.subtract(const Duration(days: 3)));
    if (isClosingDay) {
      NotificationService().cancelClosingWindowWarning();
    }
  }
}