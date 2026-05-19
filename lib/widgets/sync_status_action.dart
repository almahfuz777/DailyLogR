import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dailylogr/providers/sync_provider.dart';
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:dailylogr/widgets/auth_sheet.dart';

class SyncStatusAction extends ConsumerWidget {
  const SyncStatusAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return IconButton(
            icon: const Icon(Icons.cloud_off_outlined),
            tooltip: 'Not synced',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cloud Sync'),
                  content: const Text('Sign in to back up and sync your logs with the cloud.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        showAuthSheet(context); // open auth sheet
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              );
            },
          );
        }

        final status = ref.watch(syncStatusProvider);

        IconData icon;
        Color? color;
        String tooltip;

        switch (status) {
          case SyncStatus.synced:
            icon = Icons.cloud_done_outlined;
            tooltip = 'Synced to cloud';
            break;
          case SyncStatus.syncing:
            icon = Icons.cloud_upload_outlined;
            tooltip = 'Syncing...';
            break;
          case SyncStatus.offline:
            icon = Icons.cloud_off_outlined;
            color = Colors.orange;
            tooltip = 'Offline';
            break;
          case SyncStatus.error:
            icon = Icons.error_outline;
            color = Colors.red;
            tooltip = 'Sync Error';
            break;
        }

        return IconButton(
          icon: Icon(icon, color: color),
          tooltip: tooltip,
          onPressed: () async {
             if (status == SyncStatus.syncing) return;
             
             try {
                await ref.read(syncStatusProvider.notifier).sync();
             } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sync failed: $e')),
                   );
                }
             }
          },
        );
      },
    );
  }
}
