class DayKey {
  /// Format date as YYYY-MM-DD (used as unique key)
  static String of(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _fullMonths = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  /// Compact format (mmm dd)
  static String ofShort(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  /// Long format (Weekday, DD Month, YYYY)
  static String ofLong(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_fullMonths[d.month - 1]}, ${d.year}';

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
