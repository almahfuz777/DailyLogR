import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dailylogr/services/sync_service.dart';
import 'package:dailylogr/providers/journal_provider.dart';
import 'package:dailylogr/providers/user_config_provider.dart';

enum SyncStatus { synced, syncing, offline, error }

class SyncStatusNotifier extends Notifier<SyncStatus> with WidgetsBindingObserver {
  @override
  SyncStatus build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    _initConnectivity();
    return SyncStatus.offline;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Sync on resume covers the multi-device case: if another device made changes while this app was backgrounded, they appear as soon as the user returns.
    if (lifecycle == AppLifecycleState.resumed) {
      _performAutoSync();
    }
  }

  Future<void> _initConnectivity() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    _updateStatusFromConnectivity(connectivityResults);

    final subscription = Connectivity()
        .onConnectivityChanged
        .listen(_updateStatusFromConnectivity);
    ref.onDispose(subscription.cancel);
  }

  void _updateStatusFromConnectivity(List<ConnectivityResult> results) {
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    if (isOffline) {
      state = SyncStatus.offline;
    } else {
      if (state == SyncStatus.offline || state == SyncStatus.error) {
         _performAutoSync();
      }
    }
  }

  Future<void> _performAutoSync() async {
    try {
      await sync();
    } catch (_) {
      // Auto-sync failure is handled quietly by the sync() method
    }
  }

  /// Pulls from Firestore and merges into Hive. Updates [SyncStatus] reactively.
  /// Concurrent calls are de-duplicated: if a sync is already in progress, this is a no-op to avoid redundant server round-trips.
  Future<void> sync() async {
    if (state == SyncStatus.syncing) return; // de-duplicate concurrent calls

    // Check real connectivity before touching Firestore so it doesn't fall back to local cache
    final results = await Connectivity().checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) {
      state = SyncStatus.offline;
      return;
    }

    state = SyncStatus.syncing;
    try {
      await SyncService.pullSync();
      state = SyncStatus.synced;
      ref.invalidate(journalProvider); // Always update UI once sync finishes!
      ref.invalidate(userConfigProvider); // Update user config provider when sync completes
    } catch (e) {
      state = SyncStatus.error;
      rethrow;
    }
  }

  void setStatus(SyncStatus newStatus) {
    state = newStatus;
  }
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(() {
  return SyncStatusNotifier();
});
