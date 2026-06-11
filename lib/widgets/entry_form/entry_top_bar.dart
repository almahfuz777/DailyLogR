// lib/widgets/entry_form/entry_top_bar.dart
import 'package:flutter/material.dart';

/// Top app bar for the Entry Form.
/// Contains back, undo/redo, and save actions.
class EntryTopBar extends StatelessWidget {
  final bool readOnly;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onBulletList;
  final VoidCallback? onNumberedList;

  const EntryTopBar({
    super.key,
    required this.readOnly,
    this.canUndo = false,
    this.canRedo = false,
    required this.onBack,
    required this.onSave,
    this.onUndo,
    this.onRedo,
    this.onBulletList,
    this.onNumberedList,
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            tooltip: readOnly ? 'Close' : 'Discard',
          ),
          if (!readOnly) ...[
            Container(
              height: 20,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: color.outlineVariant.withValues(alpha: 0.5),
            ),
            if (canUndo || canRedo) ...[
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                onPressed: canUndo ? onUndo : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                onPressed: canRedo ? onRedo : null,
                tooltip: 'Redo',
              ),
            ],
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted, size: 20),
              onPressed: onBulletList,
              tooltip: 'Bulleted list',
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered, size: 20),
              onPressed: onNumberedList,
              tooltip: 'Numbered list',
            ),
          ],
          const Spacer(),
          if (!readOnly)
            MediaQuery.sizeOf(context).width < 360
                ? IconButton.filledTonal(
                    onPressed: onSave,
                    icon: const Icon(Icons.check, size: 20),
                    tooltip: 'Save',
                  )
                : FilledButton.tonalIcon(
                    onPressed: onSave,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save'),
                  ),
        ],
      ),
    );
  }
}

