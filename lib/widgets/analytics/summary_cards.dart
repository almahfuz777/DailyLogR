// lib/widgets/analytics/summary_cards.dart
import 'package:flutter/material.dart';

class AnalyticsSummaryCards extends StatelessWidget {
  final int streak;
  final int totalEntries;
  final double averageRating;

  const AnalyticsSummaryCards({
    super.key,
    required this.streak,
    required this.totalEntries,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Streak',
            value: '$streak',
            subtitle: 'Days',
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'Entries',
            value: '$totalEntries',
            subtitle: 'Total logs',
            icon: Icons.book,
            iconColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'Avg Rating',
            value: averageRating.toStringAsFixed(1),
            subtitle: 'Out of 5',
            icon: Icons.star,
            iconColor: Colors.amber,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
