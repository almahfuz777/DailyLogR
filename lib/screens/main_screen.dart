// lib/screens/main_screen.dart
import 'dart:async';
import 'package:dailylogr/utils/app_screens.dart';
import 'package:dailylogr/screens/analytics_screen.dart';
import 'package:dailylogr/screens/dashboard_screen.dart';
import 'package:dailylogr/screens/entries_screen.dart';
import 'package:dailylogr/screens/settings_screen.dart';
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/providers/journal_provider.dart';
import 'package:dailylogr/widgets/auth_sheet.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:dailylogr/widgets/home_drawer.dart';
import 'package:dailylogr/widgets/sync_status_action.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/providers/sync_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  AppScreen _currentScreen = AppScreen.dashboard;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuthService.authStateChanges.listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Switches the active Hive box whenever the Firebase user changes, then invalidates the journal provider so the UI re-reads from the correct user-specific box.
  Future<void> _onAuthChanged(User? user) async {
    await HiveService.switchUser(user?.uid);

    // On login: ask about existing anonymous entries before refreshing UI.
    if (user != null && HiveService.hasAnonymousEntries && mounted) {
      await _showMigrationDialog();
    }

    ref.invalidate(journalProvider);

    // If a user just logged in, trigger a sync to pull their cloud data immediately!
    if (user != null) {
      ref.read(syncStatusProvider.notifier).sync().catchError((e) {});
    }
  }

  /// Asks the user whether to merge or discard existing local entries
  Future<void> _showMigrationDialog() async {
    final count = HiveService.anonymousEntryCount;
    final result = await showDialog<bool>(
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

    if (result == true) {
      await HiveService.migrateAnonymousEntries();
    } else {
      await HiveService.discardAnonymousEntries();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    Navigator.of(context).pop(); // close drawer first
    try {
      final credential = await FirebaseAuthService.signInWithGoogle();
      final email = credential.user?.email;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(email == null ? 'Signed in.' : 'Signed in as $email.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('canceled') || errorStr.contains('aborted')) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in failed: $error')));
    }
  }

  Future<void> _handleLogout() async {
    Navigator.of(context).pop(); // close drawer first
    try {
      await FirebaseAuthService.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $error')),
      );
    }
  }

  void _onScreenSelected(AppScreen screen) {
    setState(() => _currentScreen = screen);
    Navigator.of(context).pop(); // close drawer
  }

  // Get title based on current section
  String get _screenTitle {
    switch (_currentScreen) {
      case AppScreen.dashboard:
        return 'Dashboard';
      case AppScreen.entries:
        return 'All Entries';
      case AppScreen.analytics:
        return 'Analytics';
      case AppScreen.settings:
        return 'Settings';
    }
  }

  // Set screen body based on current section
  Widget _buildBody() {
    switch (_currentScreen) {
      case AppScreen.dashboard:
        return const DashboardScreen();
      case AppScreen.entries:
        return const EntriesScreen();
      case AppScreen.analytics:
        return const AnalyticsScreen();
      case AppScreen.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      // AppBar
      appBar: AppBar(
        title: Text(_screenTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: color.primary,
        foregroundColor: color.onPrimary,
        actions: const [
          SyncStatusAction(),
        ],
      ),

      // Drawer
      drawer: HomeDrawer(
        currentScreen: _currentScreen,
        onScreenSelected: _onScreenSelected,
        onGoogleSignIn: _handleGoogleSignIn,
        onLoginSignup: () {
          Navigator.of(context).pop(); // close drawer first
          showAuthSheet(context);
        },
        onLogout: _handleLogout,
      ),

      // FAB (Floating Action Button)
      floatingActionButton:
          (_currentScreen == AppScreen.dashboard ||
              _currentScreen == AppScreen.entries)
          ? FloatingActionButton(
              onPressed: () => entryEditorSheet(context, ref),
              backgroundColor: color.primary,
              foregroundColor: color.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,

      body: _buildBody(),
    );
  }
}
