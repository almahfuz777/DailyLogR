// lib/screens/main_screen.dart
import 'package:dailylogr/utils/app_screens.dart';
import 'package:dailylogr/screens/analytics_screen.dart';
import 'package:dailylogr/screens/dashboard_screen.dart';
import 'package:dailylogr/screens/entries_screen.dart';
import 'package:dailylogr/screens/settings_screen.dart';
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:dailylogr/widgets/auth_sheet.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:dailylogr/widgets/home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  AppScreen _currentScreen = AppScreen.dashboard;

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
