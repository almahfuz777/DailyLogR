// lib/widgets/home_drawer.dart
import 'package:dailylogr/utils/app_screens.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeDrawer extends StatelessWidget {
  final AppScreen currentScreen;
  final ValueChanged<AppScreen> onScreenSelected;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onLoginSignup;
  final VoidCallback onLogout;

  const HomeDrawer({
    super.key,
    required this.currentScreen,
    required this.onScreenSelected,
    required this.onGoogleSignIn,
    required this.onLoginSignup,
    required this.onLogout,
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
                    selected: currentScreen == AppScreen.dashboard,
                    onTap: () => onScreenSelected(AppScreen.dashboard),
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt_outlined),
                    title: const Text('All Entries'),
                    selected: currentScreen == AppScreen.entries,
                    onTap: () => onScreenSelected(AppScreen.entries),
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: const Text('Analytics'),
                    selected: currentScreen == AppScreen.analytics,
                    onTap: () => onScreenSelected(AppScreen.analytics),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    selected: currentScreen == AppScreen.settings,
                    onTap: () => onScreenSelected(AppScreen.settings),
                  ),
                ],
              ),
            ),


            // Footer
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: StreamBuilder<User?>(
                stream: FirebaseAuthService.authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data;

                  if (user != null) {
                    // Logged In State
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: user.photoURL != null 
                                  ? NetworkImage(user.photoURL!) 
                                  : null,
                              child: user.photoURL == null 
                                  ? const Icon(Icons.person, size: 16) 
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? 'Journaler',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user.email ?? '',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Log Out'),
                        ),
                      ],
                    );
                  }

                  // Logged Out State
                  return Column(
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
