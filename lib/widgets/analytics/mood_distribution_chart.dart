// lib/widgets/analytics/mood_distribution_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodDistributionChart extends StatelessWidget {
  final Map<String, int> moodCounts;
  final String title;

  const MoodDistributionChart({
    super.key,
    required this.moodCounts,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    // Sort by count descending
    final sortedEntries = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors for the pie chart
    final List<Color> colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    List<PieChartSectionData> sections = [];
    int total = moodCounts.values.fold(0, (sum, count) => sum + count);

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final color = colors[i % colors.length];
      final percentage = (entry.value / total) * 100;

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
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
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: sections,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      final color = colors[index % colors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key} (${entry.value})',
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
