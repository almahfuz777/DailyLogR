// lib/widgets/analytics/rating_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RatingTrendChart extends StatelessWidget {
  final Map<DateTime, double> trendData;
  final String title;

  const RatingTrendChart({
    super.key,
    required this.trendData,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    // Sort dates
    final sortedDates = trendData.keys.toList()..sort();
    
    // Create spots
    List<FlSpot> spots = [];
    double minX = 0;
    double maxX = (sortedDates.length - 1).toDouble();

    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendData[sortedDates[i]]!));
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < sortedDates.length) {
                          // Show fewer labels if there are many data points to avoid crowding
                          if (sortedDates.length > 7 && index % ((sortedDates.length / 5).ceil()) != 0) {
                             return const SizedBox.shrink();
                          }
                          final date = sortedDates[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM d').format(date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value > 5) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: minX,
                maxX: maxX,
                minY: 1,
                maxY: 5.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
