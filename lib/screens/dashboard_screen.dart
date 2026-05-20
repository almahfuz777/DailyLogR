// lib/screens/dashboard_screen.dart
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/providers/streak_provider.dart';
import 'package:dailylogr/widgets/activity_calendar_strip.dart';
import 'package:dailylogr/widgets/dashboard_entry_carousel.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:dailylogr/widgets/streak_summary_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/journal_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final DashboardEntryCarouselController _carouselController = 
      DashboardEntryCarouselController();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalProvider);
    final streak = ref.watch(streakProvider);
    final carouselItems = DashboardCarouselItems.fromEntries(entries);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final carouselHeight = (screenHeight * 0.48).clamp(340.0, 430.0);

    return StreamBuilder<User?>(
      stream: FirebaseAuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final color = Theme.of(context).colorScheme;

        String? displayName = user?.displayName;
        if (displayName == null && user?.email != null) {
          final emailPrefix = user!.email!.split('@')[0];
          displayName = emailPrefix.isNotEmpty
              ? '${emailPrefix[0].toUpperCase()}${emailPrefix.substring(1)}'
              : emailPrefix;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Personalized Greeting
            Padding(
              padding: const EdgeInsets.only(
                bottom: 6,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName != null ? '$displayName!' : 'Ready to log?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Activity calendar strip
            ActivityCalendarStrip(
              entries: entries,
              onDateTapped: (date) {
                final dateKey = DayKey.of(DayKey.normalize(date));
                final index = carouselItems.indexWhere(
                    (item) => DayKey.of(item.date) == dateKey);

                if (index != -1) {
                  _carouselController.animateToPage(index);
                } else if (!DayKey.isWithinEditWindow(date)) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No entry for this day'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            
            StreakSummaryCard(streak: streak),
            const SizedBox(height: 4),  // Spacing

            // Carousel
            SizedBox(
              height: carouselHeight,
              child: DashboardEntryCarousel(
                items: carouselItems,
                controller: _carouselController,
                onCardTap: (item) {
                  if (item.entry != null) {
                    entryEditorSheet(context, ref, initial: item.entry);
                  } else if (DayKey.isWithinEditWindow(item.date)) {
                    entryEditorSheet(context, ref, initialDate: item.date);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
