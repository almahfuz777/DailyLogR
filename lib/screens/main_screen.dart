// lib/screens/main_screen.dart
import 'package:dailylogr/utils/app_screens.dart';
import 'package:dailylogr/providers/auth_lifecycle_provider.dart';
import 'package:dailylogr/providers/journal_provider.dart';
import 'package:dailylogr/screens/entries_screen.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/auth_sheet.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:dailylogr/widgets/home_drawer.dart';
import 'package:dailylogr/widgets/sync_status_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  AppScreen _currentScreen = AppScreen.dashboard;

  @override
  void initState() {
    super.initState();
    // Initialize the auth lifecycle provider so it starts listening to auth changes immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authLifecycleProvider);
    });
  }

  void _onScreenSelected(AppScreen screen) {
    setState(() => _currentScreen = screen);
    Navigator.of(context).pop(); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    // React to pending migration signal from the auth lifecycle provider.
    ref.listen<PendingMigration?>(pendingMigrationProvider, (_, pending) {
      if (pending != null) _showMigrationDialog(pending.count);
    });

    final selectedEntries = _currentScreen == AppScreen.entries 
        ? ref.watch(selectedEntriesProvider) 
        : <String>{};

    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      appBar: selectedEntries.isNotEmpty
          ? AppBar(
              backgroundColor: color.surfaceContainerHighest,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(selectedEntriesProvider.notifier).state = {};
                },
              ),
              title: Text('${selectedEntries.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete entries?'),
                        content: Text('Delete ${selectedEntries.length} selected entries?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final notifier = ref.read(journalProvider.notifier);
                      final entries = ref.read(journalProvider);
                      final entriesToDelete = entries.where(
                        (entry) => selectedEntries.contains(DayKey.of(DayKey.normalize(entry.date)))
                      ).toList();
                      
                      for (final e in entriesToDelete) {
                        await notifier.deleteEntry(e);
                      }
                      ref.read(selectedEntriesProvider.notifier).state = {};
                    }
                  },
                ),
              ],
            )
          : AppBar(
              title: Text(_currentScreen.label),
              centerTitle: true,
              elevation: 0,
              backgroundColor: color.primary,
              foregroundColor: color.onPrimary,
              actions: const [SyncStatusAction()],
            ),

      drawer: HomeDrawer(
        currentScreen: _currentScreen,
        onScreenSelected: _onScreenSelected,
        onLoginSignup: () {
          Navigator.of(context).pop();
          showAuthSheet(context);
        },
      ),

      floatingActionButton: _currentScreen.showFab
          ? FloatingActionButton(
              onPressed: () => entryEditorSheet(context, ref),
              backgroundColor: color.primary,
              foregroundColor: color.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,

      body: _currentScreen.buildBody(),
    );
  }

  /// Shows the anonymous-entry migration dialog
  Future<void> _showMigrationDialog(int count) async {
    // Clear the signal immediately so it doesn't re-trigger.
    ref.read(pendingMigrationProvider.notifier).state = null;

    final merge = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Local Entries Found'),
        content: Text(
          'You have $count local ${count == 1 ? 'entry' : 'entries'} '
          'created before signing in.\n\n'
          'Would you like to sync them to your account, '
          'or discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sync to Account'),
          ),
        ],
      ),
    );

    if (merge == true) {
      await HiveService.migrateAnonymousEntries();
    } else {
      await HiveService.discardAnonymousEntries();
    }
  }
}
