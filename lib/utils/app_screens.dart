// lib/utils/app_screens.dart
import 'package:dailylogr/screens/analytics_screen.dart';
import 'package:dailylogr/screens/dashboard_screen.dart';
import 'package:dailylogr/screens/entries_screen.dart';
import 'package:dailylogr/screens/settings_screen.dart';
import 'package:flutter/material.dart';

/// Defines the top-level navigation destinations of the app.
enum AppScreen {
  dashboard(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    showFab: true,
  ),
  entries(
    label: 'All Entries',
    icon: Icons.list_alt_outlined,
    showFab: true,
  ),
  analytics(
    label: 'Analytics',
    icon: Icons.insights_outlined,
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
  );

  final String label;
  final IconData icon;
  final bool showFab;

  const AppScreen({
    required this.label,
    required this.icon,
    this.showFab = false,
  });

  /// Returns the root widget for this screen destination.
  Widget buildBody() {
    return switch (this) {
      AppScreen.dashboard => const DashboardScreen(),
      AppScreen.entries => const EntriesScreen(),
      AppScreen.analytics => const AnalyticsScreen(),
      AppScreen.settings => const SettingsScreen(),
    };
  }
}
