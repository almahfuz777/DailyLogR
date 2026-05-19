import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dailylogr/utils/date_helper.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>>? get _userEntriesRef {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('entries');
  }

  /// Pushes an entry to Firestore.
  /// If offline, Firestore caches this locally and automatically sends it when online.
  static Future<void> pushEntry(JournalEntry entry) async {
    final ref = _userEntriesRef;
    if (ref == null) return;

    // Use DayKey as the globally unique ID (enforces 1 entry per day in cloud)
    final docId = DayKey.of(DayKey.normalize(entry.date));

    await ref.doc(docId).set({
      'date': entry.date.toIso8601String(),
      'title': entry.title,
      'note': entry.note,
      'adjective': entry.adjective,
      'rating': entry.rating,
      'updatedAt': entry.updatedAt.toIso8601String(),
      'isDeleted': entry.isDeleted,
      'deletedAt': entry.deletedAt?.toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Pulls all entries from Firestore and merges them with Hive using Last-Write-Wins.
  static Future<void> pullSync() async {
    final ref = _userEntriesRef;
    if (ref == null) return;

    final snapshot = await ref.get(const GetOptions(source: Source.serverAndCache));
    final cloudKeys = <String>{};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final docId = doc.id; // Which is the DayKey
      cloudKeys.add(docId);

      final cloudEntry = JournalEntry(
        id: docId,
        date: DateTime.parse(data['date'] as String),
        title: data['title'] as String?,
        note: data['note'] as String,
        adjective: data['adjective'] as String?,
        rating: data['rating'] as int?,
        updatedAt: DateTime.parse(data['updatedAt'] as String),
        isDeleted: data['isDeleted'] as bool? ?? false,
        deletedAt: data['deletedAt'] != null 
            ? DateTime.parse(data['deletedAt'] as String) 
            : null,
      );

      final localEntry = HiveService.journalBox.get(docId);

      if (localEntry == null) {
        // Does not exist locally, save it directly to Hive (bypassing the conflict check)
        await HiveService.journalBox.put(docId, cloudEntry);
      } else {
        // Exists locally, conflict resolution (Last-Write-Wins)
        if (cloudEntry.updatedAt.isAfter(localEntry.updatedAt)) {
          // Cloud is newer
          await HiveService.journalBox.put(docId, cloudEntry);
        } else if (localEntry.updatedAt.isAfter(cloudEntry.updatedAt)) {
          // Local is newer, push local to cloud
          await pushEntry(localEntry);
        }
      }
    }

    // Push local entries that don't exist in the cloud yet
    for (var key in HiveService.journalBox.keys) {
      if (!cloudKeys.contains(key)) {
        final localEntry = HiveService.journalBox.get(key);
        if (localEntry != null) {
          await pushEntry(localEntry);
        }
      }
    }
  }

  /// Hard deletes an entry from Firestore.
  static Future<void> permanentlyDeleteEntry(JournalEntry entry) async {
    final ref = _userEntriesRef;
    if (ref == null) return;
    final docId = DayKey.of(DayKey.normalize(entry.date));
    await ref.doc(docId).delete();
  }
}
