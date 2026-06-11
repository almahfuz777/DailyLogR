// lib/providers/user_config_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/models/user_config.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/services/sync_service.dart';

class UserConfigNotifier extends Notifier<UserConfig> {
  @override
  UserConfig build() {
    final box = HiveService.configBox;
    // Watch for changes in Hive (optional, but good if sync pulls new data in background)
    // Actually, HiveService.switchUser happens when login state changes, we might need to invalidate this provider.
    // For now, just return the current value or a new default one.
    return box.get('main', defaultValue: UserConfig())!;
  }

  Future<void> addCustomMood(String mood) async {
    if (state.customMoods.contains(mood)) return;

    final newMoods = [...state.customMoods, mood];
    final updated = state.copyWith(
      customMoods: newMoods,
      updatedAt: DateTime.now(),
    );

    state = updated;
    await HiveService.configBox.put('main', updated);
    await SyncService.pushUserConfig(updated);
  }

  Future<void> removeCustomMood(String mood) async {
    if (!state.customMoods.contains(mood)) return;

    final newMoods = state.customMoods.where((m) => m != mood).toList();
    final updated = state.copyWith(
      customMoods: newMoods,
      updatedAt: DateTime.now(),
    );

    state = updated;
    await HiveService.configBox.put('main', updated);
    await SyncService.pushUserConfig(updated);
  }

  Future<void> updateCustomMood(String oldMood, String newMood) async {
    if (!state.customMoods.contains(oldMood)) return;

    final newMoods = state.customMoods.map((m) => m == oldMood ? newMood : m).toList();
    final updated = state.copyWith(
      customMoods: newMoods,
      updatedAt: DateTime.now(),
    );

    state = updated;
    await HiveService.configBox.put('main', updated);
    await SyncService.pushUserConfig(updated);
  }

  Future<void> setFirstDayOfWeek(int day) async {
    if (state.firstDayOfWeek == day) return;

    final updated = state.copyWith(
      firstDayOfWeek: day,
      updatedAt: DateTime.now(),
    );

    state = updated;
    await HiveService.configBox.put('main', updated);
    await SyncService.pushUserConfig(updated);
  }

  void refresh() {
    state = HiveService.configBox.get('main', defaultValue: UserConfig())!;
  }
}

final userConfigProvider = NotifierProvider<UserConfigNotifier, UserConfig>(() {
  return UserConfigNotifier();
});
