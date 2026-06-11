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
    final scale = (MediaQuery.sizeOf(context).height / 800.0).clamp(0.7, 1.0);
    final isActive = streak.currentStreak > 0;

    final title = isActive
        ? '${streak.currentStreak} ${streak.currentStreak == 1 ? 'day' : 'days'} streak${streak.isAtRisk ? ' – at risk' : '! Keep Going...'}'
        : 'Start your streak — log today!';

    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 8 * scale),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: streak.isAtRisk
            ? color.tertiaryContainer.withValues(alpha: 0.75)
            : color.secondaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streak.isAtRisk
              ? color.tertiary.withValues(alpha: 0.16)
              : color.secondary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Text(
            '🔥',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22.0) * scale,
            ),
          ),
          SizedBox(width: 10 * scale),
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
                    fontSize: (theme.textTheme.titleSmall?.fontSize ?? 14.0) * scale,
                  ),
                ),
                if (streak.recoveryHint != null) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    streak.recoveryHint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: streak.isAtRisk
                          ? color.onTertiaryContainer.withValues(alpha: 0.78)
                          : color.onSecondaryContainer.withValues(alpha: 0.78),
                      fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12.0) * scale,
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
