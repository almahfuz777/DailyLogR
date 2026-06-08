// lib/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefFirstDayOfWeek = 'pref_first_day_of_week';

/// Dart's DateTime.weekday: Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
/// Default: Saturday (6)
const int kDefaultFirstDayOfWeek = 6;

class SettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final firstDay = prefs.getInt(_prefFirstDayOfWeek) ?? kDefaultFirstDayOfWeek;
    return UserSettings(firstDayOfWeek: firstDay);
  }

  Future<void> setFirstDayOfWeek(int dayOfWeek) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFirstDayOfWeek, dayOfWeek);
    state = AsyncData(UserSettings(firstDayOfWeek: dayOfWeek));
  }
}

class UserSettings {
  final int firstDayOfWeek;

  const UserSettings({required this.firstDayOfWeek});
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, UserSettings>(
  SettingsNotifier.new,
);
