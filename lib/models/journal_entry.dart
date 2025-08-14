import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry {
  @HiveField(0) String? id;
  @HiveField(1) DateTime date;
  @HiveField(2) String? title;
  @HiveField(3) String note;
  @HiveField(4) String? adjective;
  @HiveField(5) int? rating;
  @HiveField(6) DateTime updatedAt;

  JournalEntry({
    required this.date, // 1 date per entry
    this.title,
    required this.note,
    this.adjective,       // an adjective that represents the day
    this.rating,          // 1-5 star rating
    DateTime? updatedAt,  // last updated at
  }) : updatedAt = updatedAt?? DateTime.now();



}