// lib/widgets/entry_form/color_picker_sheet.dart
import 'package:flutter/material.dart';

/// A bottom sheet with curated pastel colors for entry backgrounds.
/// Returns the selected color as an int? (null = default/no color).
class ColorPickerSheet extends StatelessWidget {
  final int? selectedColor;

  const ColorPickerSheet({super.key, this.selectedColor});

  // Curated pastel palette
  static const List<_PaletteEntry> _palette = [
    _PaletteEntry(null, 'Default'),
    _PaletteEntry(0xFFFFF8E1, 'Warm Cream'),
    _PaletteEntry(0xFFFCE4EC, 'Soft Rose'),
    _PaletteEntry(0xFFF3E5F5, 'Lavender'),
    _PaletteEntry(0xFFE8EAF6, 'Periwinkle'),
    _PaletteEntry(0xFFE1F5FE, 'Sky Blue'),
    _PaletteEntry(0xFFE0F2F1, 'Mint'),
    _PaletteEntry(0xFFE8F5E9, 'Sage'),
    _PaletteEntry(0xFFF1F8E9, 'Lime Cream'),
    _PaletteEntry(0xFFFFF3E0, 'Peach'),
    _PaletteEntry(0xFFEFEBE9, 'Warm Grey'),
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entry Color',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _palette.map((entry) {
              final isSelected = selectedColor == entry.value;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return GestureDetector(
                onTap: () => Navigator.pop(context, entry.value),
                child: Tooltip(
                  message: entry.label,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: entry.value != null
                          ? Color(entry.value!)
                          : color.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? color.primary
                            : color.outlineVariant.withValues(alpha: 0.5),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 20, color: color.primary)
                        : entry.value == null
                            ? Icon(
                                isDark ? Icons.dark_mode_outlined : Icons.block_outlined,
                                size: 18,
                                color: color.onSurfaceVariant,
                              )
                            : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PaletteEntry {
  final int? value;
  final String label;
  const _PaletteEntry(this.value, this.label);
}
