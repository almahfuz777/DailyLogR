import 'package:hive/hive.dart';

part 'user_config.g.dart';

@HiveType(typeId: 1)
class UserConfig {
  @HiveField(0) List<String> customMoods;
  @HiveField(1) int firstDayOfWeek;
  @HiveField(2) DateTime updatedAt;

  UserConfig({
    List<String>? customMoods,
    int? firstDayOfWeek,
    DateTime? updatedAt,
  })  : customMoods = customMoods ?? [],
        firstDayOfWeek = firstDayOfWeek ?? 6, // Default Saturday
        updatedAt = updatedAt ?? DateTime.now();

  UserConfig copyWith({
    List<String>? customMoods,
    int? firstDayOfWeek,
    DateTime? updatedAt,
  }) {
    return UserConfig(
      customMoods: customMoods ?? this.customMoods,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Factory to create from Firestore JSON map
  factory UserConfig.fromJson(Map<String, dynamic> json) {
    return UserConfig(
      customMoods: (json['customMoods'] as List<dynamic>?)?.cast<String>(),
      firstDayOfWeek: json['firstDayOfWeek'] as int?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'customMoods': customMoods,
      'firstDayOfWeek': firstDayOfWeek,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
