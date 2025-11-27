// lib/widgets/home_drawer.dart
import 'package:flutter/material.dart';
import 'package:dailylogr/screens/main_screen.dart'; // for Screens enum

class HomeDrawer extends StatelessWidget {
  final Screens currentScreen;
  final ValueChanged<Screens> onScreenSelected;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onLoginSignup;

  const HomeDrawer({
    super.key,
    required this.currentScreen,
    required this.onScreenSelected,
    required this.onGoogleSignIn,
    required this.onLoginSignup,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header + Navigation
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Header
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: color.primary,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        'DailyLogR',
                        style: TextStyle(
                          color: color.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Navigation screen options
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: const Text('Dashboard'),
                    selected: currentScreen == Screens.dashboard,
                    onTap: () => onScreenSelected(Screens.dashboard),
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt_outlined),
                    title: const Text('All Entries'),
                    selected: currentScreen == Screens.entries,
                    onTap: () => onScreenSelected(Screens.entries),
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: const Text('Analytics'),
                    selected: currentScreen == Screens.analytics,
                    onTap: () => onScreenSelected(Screens.analytics),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    selected: currentScreen == Screens.settings,
                    onTap: () => onScreenSelected(Screens.settings),
                  ),
                  // ListTile(
                  //   leading: const Icon(Icons.close),
                  //   title: const Text('Close'),
                  //   onTap: () => Navigator.pop(context),
                  // ),
                ],
              ),
            ),


            // Footer
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sync your journal with the cloud',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: onGoogleSignIn,
                    icon: const Icon(Icons.account_circle),
                    label: const Text('Continue with Google'),
                  ),
                  TextButton(
                    onPressed: onLoginSignup,
                    child: const Text('Login / Signup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
