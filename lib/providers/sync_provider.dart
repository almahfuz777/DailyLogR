import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dailylogr/services/sync_service.dart';

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
         state = SyncStatus.syncing;
         _performAutoSync();
      }
    }
  }

  Future<void> _performAutoSync() async {
    try {
      await SyncService.pullSync();
      state = SyncStatus.synced;
    } catch (e) {
      state = SyncStatus.error;
    }
  }

  void setStatus(SyncStatus newStatus) {
    state = newStatus;
  }
}

final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(() {
  return SyncStatusNotifier();
});
