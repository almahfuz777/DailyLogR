// lib/providers/auth_lifecycle_provider.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/providers/journal_provider.dart';
import 'package:dailylogr/providers/sync_provider.dart';

/// Tracks pending anonymous entry migration state so the UI can reactively show a dialog when needed.
class PendingMigration {
  final int count;
  const PendingMigration(this.count);
}

final pendingMigrationProvider = StateProvider<PendingMigration?>((ref) => null);

/// A long-lived provider that listens to Firebase auth state changes and orchestrates the side-effects: switching Hive boxes, invalidating journal data, and triggering cloud sync.
final authLifecycleProvider = Provider<AuthLifecycle>((ref) {
  final lifecycle = AuthLifecycle(ref);
  ref.onDispose(lifecycle.dispose);
  return lifecycle;
});

class AuthLifecycle {
  final Ref _ref;
  late final StreamSubscription<User?> _authSub;

  AuthLifecycle(this._ref) {
    _authSub = FirebaseAuthService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    await HiveService.switchUser(user?.uid);

    // Signal the UI that anonymous entries exist and need user decision.
    if (user != null && HiveService.hasAnonymousEntries) {
      _ref.read(pendingMigrationProvider.notifier).state =
          PendingMigration(HiveService.anonymousEntryCount);
    }

    _ref.invalidate(journalProvider);

    if (user != null) {
      _ref.read(syncStatusProvider.notifier).sync().catchError((e) {});
    }
  }

  void dispose() {
    _authSub.cancel();
  }
}
