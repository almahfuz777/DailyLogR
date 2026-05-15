class DayKey {
  /// Format date as YYYY-MM-DD (used as unique key)
  static String of(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Strip time portion, keep only date
  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The earliest date a user may create or edit an entry.
  static const int _editWindowDays = 3;

  static DateTime get editWindowStart =>
      normalize(DateTime.now()).subtract(const Duration(days: _editWindowDays));

  /// Returns true if [date] falls within the allowed create/edit window.
  static bool isWithinEditWindow(DateTime date) {
    final today = normalize(DateTime.now());
    final normalized = normalize(date);
    return !normalized.isBefore(editWindowStart) && !normalized.isAfter(today);
  }
}
