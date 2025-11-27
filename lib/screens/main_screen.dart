// lib/screens/home_screen.dart
import 'package:dailylogr/screens/analytics_screen.dart';
import 'package:dailylogr/screens/dashboard_screen.dart';
import 'package:dailylogr/screens/settings_screen.dart';
import 'package:dailylogr/widgets/entry_creator_sheet.dart';
import 'package:dailylogr/widgets/home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/screens/entries_screen.dart';

enum Screens {
  dashboard,
  entries,
  analytics,
  settings,
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Screens _currentScreen = Screens.dashboard;

  // Handle screen selection from drawer 
  void _onScreenSelected(Screens screen) {
    setState(() => _currentScreen = screen);
    Navigator.of(context).pop(); // close drawer
  }

  // Get title based on current section
  String get _screenTitle {
    switch (_currentScreen) {
      case Screens.dashboard:
        return 'Dashboard';
      case Screens.entries:
        return 'All Entries';
      case Screens.analytics:
        return 'Analytics';
      case Screens.settings:
        return 'Settings';
    }
  }

  // Set screen body based on current section
  Widget _buildBody() {
    switch (_currentScreen) {
      case Screens.dashboard:
        return DashboardScreen();
      case Screens.entries:
        return const EntriesScreen();
      case Screens.analytics:
        return const AnalyticsScreen();
      case Screens.settings:
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
        
        // User Authentication Callbacks
        onGoogleSignIn: () {
          // TODO: Firebase Google Sign-In
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cloud sync not implemented yet.')),
          );
        },
        onLoginSignup: () {
          // TODO: Login/Signup screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login/Signup not implemented yet.')),
          );
        },
      ),

      // FAB (Floating Action Button)
      floatingActionButton: 
        (_currentScreen == Screens.dashboard || _currentScreen == Screens.entries)
          ? FloatingActionButton(
              onPressed: () => openEntryCreatorSheet(context),
              backgroundColor: color.primary,
              foregroundColor: color.onPrimary,
              child: const Icon(Icons.add),
            )
          : null,

      body: _buildBody(),
    );
  }
}
