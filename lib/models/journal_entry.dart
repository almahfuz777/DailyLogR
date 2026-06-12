import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 0)
class JournalEntry {
  @HiveField(0) String id;
  @HiveField(1) DateTime date;
  @HiveField(2) String? title;
  @HiveField(3) String note;
  @HiveField(4) String? adjective;
  @HiveField(5) int? rating;
  @HiveField(6) DateTime updatedAt;
  @HiveField(7) bool isDeleted;
  @HiveField(8) DateTime? deletedAt;
  @HiveField(9) int? entryColor;

  JournalEntry({
    String? id,
    required this.date, // 1 date per entry
    this.title,
    required this.note,
    this.adjective,       // an adjective that represents the day
    this.rating,          // 1-5 star rating
    DateTime? updatedAt,  // last updated at
    this.isDeleted = false,
    this.deletedAt,
    this.entryColor,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? note,
    String? adjective,
    int? rating,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    int? entryColor,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      note: note ?? this.note,
      adjective: adjective ?? this.adjective,
      rating: rating ?? this.rating,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      entryColor: entryColor ?? this.entryColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'note': note,
      'adjective': adjective,
      'rating': rating,
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'entryColor': entryColor,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String?,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String?,
      note: json['note'] as String,
      adjective: json['adjective'] as String?,
      rating: json['rating'] as int?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      entryColor: json['entryColor'] as int?,
    );
  }
}