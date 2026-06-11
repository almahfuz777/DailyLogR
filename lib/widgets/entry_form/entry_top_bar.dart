// lib/widgets/entry_form/entry_top_bar.dart
import 'package:flutter/material.dart';

/// A modular top app bar for the Entry Form.
/// Contains the back button and the save button.
class EntryTopBar extends StatelessWidget {
  final bool readOnly;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const EntryTopBar({
    super.key,
    required this.readOnly,
    required this.onBack,
    required this.onSave,
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
          const Spacer(),
          if (!readOnly)
            FilledButton.tonalIcon(
              onPressed: onSave,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save'),
            ),
        ],
      ),
    );
  }
}
