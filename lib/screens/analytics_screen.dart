// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/journal_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/user_config_provider.dart';
import '../models/journal_entry.dart';
import '../utils/analytics_helper.dart';
import '../widgets/analytics/summary_cards.dart';
import '../widgets/analytics/rating_trend_chart.dart';
import '../widgets/analytics/mood_distribution_chart.dart';
import '../widgets/analytics/activity_heatmap.dart';

enum TimeFilter { week, month, allTime }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  TimeFilter _selectedFilter = TimeFilter.allTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allEntries = ref.watch(journalProvider);
    final userConfig = ref.watch(userConfigProvider);
    final firstDayOfWeek = userConfig.firstDayOfWeek;

    // Filter entries based on selection
    List<JournalEntry> filteredEntries;
    final now = DateTime.now();

    // Calendar-accurate boundaries
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Days to subtract to reach the user's preferred first weekday
    final daysSinceWeekStart = (now.weekday - firstDayOfWeek + 7) % 7;
    final startOfWeek = startOfToday.subtract(Duration(days: daysSinceWeekStart));
    final startOfMonth = DateTime(now.year, now.month, 1);

    switch (_selectedFilter) {
      case TimeFilter.week:
        filteredEntries = AnalyticsHelper.filterEntriesByDateRange(
          allEntries,
          startOfWeek,
          now,
        );
        break;
      case TimeFilter.month:
        filteredEntries = AnalyticsHelper.filterEntriesByDateRange(
          allEntries,
          startOfMonth,
          now,
        );
        break;
      case TimeFilter.allTime:
        filteredEntries = allEntries;
        break;
    }

    // Calculate metrics
    final streakState = ref.watch(streakProvider);
    final streak = streakState.currentStreak;
    final totalEntries = filteredEntries.length;
    final averageRating = AnalyticsHelper.calculateAverageRating(filteredEntries);
    final trendData = AnalyticsHelper.getRatingTrend(filteredEntries);
    final moodCounts = AnalyticsHelper.getMoodCounts(filteredEntries);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SegmentedButton<TimeFilter>(
                segments: const [
                  ButtonSegment(
                    value: TimeFilter.week,
                    label: Text('This Week'),
                  ),
                  ButtonSegment(
                    value: TimeFilter.month,
                    label: Text('This Month'),
                  ),
                  ButtonSegment(
                    value: TimeFilter.allTime,
                    label: Text('All Time'),
                  ),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (Set<TimeFilter> newSelection) {
                  setState(() {
                    _selectedFilter = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return theme.colorScheme.primaryContainer;
                      }
                      return theme.colorScheme.surface;
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AnalyticsSummaryCards(
                  streak: streak,
                  totalEntries: totalEntries,
                  averageRating: averageRating,
                ),
                if (allEntries.length < 3) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Unlock Analytics',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add ${3 - allEntries.length} more entries to unlock your rating trends and mood distribution charts.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  if (trendData.isNotEmpty)
                    RatingTrendChart(
                      title: 'Rating Trend',
                      trendData: trendData,
                    )
                  else
                    _buildEmptyChartPlaceholder(
                      context,
                      title: 'Rating Trend',
                      message: 'Not enough rating data available.\nAdd ratings to your entries to view rating trend.',
                      icon: Icons.show_chart,
                    ),
                  const SizedBox(height: 24),
                  if (moodCounts.isNotEmpty)
                    MoodDistributionChart(
                      title: 'Mood Distribution',
                      moodCounts: moodCounts,
                    )
                  else
                    _buildEmptyChartPlaceholder(
                      context,
                      title: 'Mood Distribution',
                      message: 'Not enough mood data available.\n Add moods to your entries to view mood distribution.',
                      icon: Icons.pie_chart_outline,
                    ),
                ],
                const SizedBox(height: 24),
                ActivityHeatmap(
                  entries: allEntries, // Always show all time for heatmap context
                ),
                const SizedBox(height: 100), // Bottom padding for scrolling
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartPlaceholder(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}