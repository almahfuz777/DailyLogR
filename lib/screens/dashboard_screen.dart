// lib/screens/dashboard_screen.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/today_entry_card.dart';
import 'package:dailylogr/widgets/write_prompt_card.dart';
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/journal_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider);

    final todayKey = DayKey.of(DayKey.normalize(DateTime.now()));

    // Find today's entry in the list
    final todayEntry = entries.where((e) {
      return DayKey.of(DayKey.normalize(e.date)) == todayKey;
    }).firstOrNull;

    return StreamBuilder<User?>(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        
        // Use Google displayName, fallback to email prefix if email/pass login
        String? displayName = user?.displayName;
        if (displayName == null && user?.email != null) {
          // Capitalize first letter of email prefix for better UX
          final emailPrefix = user!.email!.split('@')[0];
          displayName = emailPrefix.isNotEmpty 
              ? '${emailPrefix[0].toUpperCase()}${emailPrefix.substring(1)}'
              : emailPrefix;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personalized Greeting Section
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 4, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName != null ? '$displayName!' : 'Ready to log?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
              
              // Today's Entry Component
              todayEntry == null
                  ? const WritePromptCard()
                  : TodayEntryCard(entry: todayEntry),
            ],
          ),
        );
      },
    );
  }
}
