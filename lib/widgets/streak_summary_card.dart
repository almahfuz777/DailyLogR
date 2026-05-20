// lib/widgets/streak_summary_card.dart
import 'package:dailylogr/providers/streak_provider.dart';
import 'package:flutter/material.dart';

/// Compact dashboard card showing the current journal streak.
class StreakSummaryCard extends StatelessWidget {
  final StreakState streak;

  const StreakSummaryCard({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isActive = streak.currentStreak > 0;

    final title = isActive
        ? '${streak.currentStreak} ${streak.currentStreak == 1 ? 'day' : 'days'} streak${streak.isAtRisk ? ' – at risk' : ''}'
        : 'Start your streak — log today!';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: streak.isAtRisk
            ? color.tertiaryContainer.withValues(alpha: 0.75)
            : color.secondaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: streak.isAtRisk
              ? color.tertiary.withValues(alpha: 0.16)
              : color.secondary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Text('🔥', style: theme.textTheme.titleLarge),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: streak.isAtRisk
                        ? color.onTertiaryContainer
                        : color.onSecondaryContainer,
                  ),
                ),
                if (streak.recoveryHint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    streak.recoveryHint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: streak.isAtRisk
                          ? color.onTertiaryContainer.withValues(alpha: 0.78)
                          : color.onSecondaryContainer.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
