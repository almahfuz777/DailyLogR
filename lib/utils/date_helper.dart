class DayKey {
  /// Format date as YYYY-MM-DD (used as unique key)
  static String of(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Strip time portion, keep only date
  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
