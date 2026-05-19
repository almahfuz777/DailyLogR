import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dailylogr/services/sync_service.dart';
import 'package:dailylogr/providers/journal_provider.dart';

enum SyncStatus { synced, syncing, offline, error }

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    _initConnectivity();
    return SyncStatus.offline;
  }

  Future<void> _initConnectivity() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    _updateStatusFromConnectivity(connectivityResults);

    Connectivity().onConnectivityChanged.listen(_updateStatusFromConnectivity);
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

  /// High-level synchronized pull/sync function. Sets state, calls SyncService.pullSync(), invalidates the journalProvider so the UI reflects the synced state immediately, and sets state to synced.
  Future<void> sync() async {
    state = SyncStatus.syncing;
    try {
      await SyncService.pullSync();
      state = SyncStatus.synced;
      ref.invalidate(journalProvider); // Always update UI once sync finishes!
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
