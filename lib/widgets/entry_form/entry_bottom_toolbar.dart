// lib/widgets/entry_form/entry_bottom_toolbar.dart
import 'package:flutter/material.dart';
import 'package:dailylogr/utils/date_helper.dart';

/// Bottom toolbar for the Entry Form.
/// Displays actionable chips for picking Date, Mood, and Rating.
/// Includes current date and last edited datetime.
class EntryBottomToolbar extends StatelessWidget {
  final DateTime date;
  final String? adjective;
  final int? rating;
  final DateTime? updatedAt;
  final int? entryColor;
  final bool readOnly;
  final bool showDeleteOption;
  final VoidCallback onPickDate;
  final VoidCallback onShowMoodPicker;
  final VoidCallback onShowRatingPicker;
  final VoidCallback onShowColorPicker;
  final VoidCallback onDelete;

  const EntryBottomToolbar({
    super.key,
    required this.date,
    this.adjective,
    this.rating,
    this.updatedAt,
    this.entryColor,
    this.readOnly = false,
    this.showDeleteOption = false,
    required this.onPickDate,
    required this.onShowMoodPicker,
    required this.onShowRatingPicker,
    required this.onShowColorPicker,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: color.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mood Row
            InkWell(
              onTap: readOnly ? null : onShowMoodPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.add_reaction_outlined, color: color.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Define your day',
                        style: TextStyle(
                          fontSize: 15,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (adjective != null) ...[
                      Text(
                        adjective!,
                        style: TextStyle(
                          fontSize: 15,
                          color: color.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: color.outlineVariant.withValues(alpha: 0.2)),
            
            // Rating Row
            InkWell(
              onTap: readOnly ? null : onShowRatingPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.star_outline, color: color.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rate your day',
                        style: TextStyle(
                          fontSize: 15,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (rating != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(rating!, (i) {
                          return const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Colors.amber,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.chevron_right, color: color.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: color.outlineVariant.withValues(alpha: 0.2)),

            // Bottom Row (Date, Color, Last Edited, Delete)
            Container(
              color: color.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Date Chip
                  InkWell(
                    onTap: readOnly ? null : onPickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: color.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            DayKey.ofShort(date),
                            style: TextStyle(
                              fontSize: 13,
                              color: color.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),

                  // Color Picker Trigger
                  InkWell(
                    onTap: onShowColorPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: entryColor != null ? Color(entryColor!) : color.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.outlineVariant.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: entryColor == null
                          ? Icon(Icons.palette_outlined, size: 14, color: color.onSurfaceVariant)
                          : null,
                    ),
                  ),

                  if (updatedAt != null) ...[
                    Expanded(
                      child: Text(
                        MediaQuery.sizeOf(context).width < 360
                            ? 'Ed: ${DayKey.ofTime(updatedAt!)}'
                            : 'Last edited: ${DayKey.ofShort(updatedAt!)} at ${DayKey.ofTime(updatedAt!)}',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  
                  // Delete icon
                  if (showDeleteOption && !readOnly) ...[
                    if (updatedAt != null) const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: color.error.withValues(alpha: 0.8)),
                      tooltip: 'Delete entry',
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: const ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
