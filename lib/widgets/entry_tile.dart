// lib/widgets/entry_tile.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/models/journal_entry.dart';

class EntryTile extends StatelessWidget {
  final JournalEntry entry;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EntryTile({
    super.key,
    required this.entry,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasTitle = entry.title?.trim().isNotEmpty ?? false;
    final mood = entry.adjective;
    final rating = entry.rating;

    final baseColor = isSelected ? color.primaryContainer : color.surfaceContainerLow;
    Color cardColor = baseColor;
    if (entry.entryColor != null) {
      final customColor = Color(entry.entryColor!);
      cardColor = isDark
          ? Color.alphaBlend(customColor.withValues(alpha: 0.12), baseColor)
          : isSelected
              ? Color.alphaBlend(customColor.withValues(alpha: 0.2), baseColor)
              : customColor;
    }

    return Card(
      elevation: isSelected ? 2 : 0,
      margin: EdgeInsets.zero,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
            ? BorderSide(color: color.primary, width: 2)
            : BorderSide(color: color.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date + Selection Checkmark
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DayKey.ofLong(entry.date),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color.onPrimaryContainer : color.onSurfaceVariant,
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: color.primary, size: 20),
                ],
              ),
              const SizedBox(height: 8),

              // Title (if any)
              if (hasTitle) ...[
                Text(
                  entry.title!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color.onPrimaryContainer : color.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Note snippet
              Text(
                entry.note.trim(),
                maxLines: hasTitle ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected 
                      ? color.onPrimaryContainer.withValues(alpha: 0.8) 
                      : color.onSurface.withValues(alpha: 0.8),
                ),
              ),

              // Chips for mood/rating
              if (mood != null || rating != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (mood != null && mood.trim().isNotEmpty)
                      _buildChip(theme, color, mood, isSelected),
                    if (rating != null)
                      _buildChip(theme, color, '⭐ $rating/5', isSelected),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, ColorScheme color, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? color.primary.withValues(alpha: 0.1) 
            : color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: isSelected ? color.primary : color.onSurfaceVariant,
        ),
      ),
    );
  }
}
