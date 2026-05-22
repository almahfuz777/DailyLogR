// lib/widgets/home_drawer.dart
import 'package:dailylogr/utils/app_screens.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeDrawer extends StatelessWidget {
  final AppScreen currentScreen;
  final ValueChanged<AppScreen> onScreenSelected;
  final VoidCallback onLoginSignup;

  const HomeDrawer({
    super.key,
    required this.currentScreen,
    required this.onScreenSelected,
    required this.onLoginSignup,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          // Header + Navigation
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    color: color.surfaceContainerHighest,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/app_logo/app_logo.png',
                          width: 64,
                          height: 64,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DailyLogR',
                        style: TextStyle(
                          color: color.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
          SafeArea(
            top: false,
            child: Padding(
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
                                  ? const Icon(Icons.person, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user.displayName != null)
                                    Text(
                                      user.displayName!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    user.email ?? 'Journaler',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout),
                              tooltip: 'Sign Out',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Sign Out'),
                                    content: const Text(
                                      'Are you sure you want to sign out?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Sign Out'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await FirebaseAuthService.signOut();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  // Logged Out State
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign in to sync your journal with the cloud',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: onLoginSignup,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In / Sign Up'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
