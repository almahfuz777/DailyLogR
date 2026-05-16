// lib/widgets/write_prompt_card.dart
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown on the dashboard when the user has not yet written today's entry.
class WritePromptCard extends ConsumerWidget {
  const WritePromptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ready to log today?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture how your day went with a quick journal entry.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => entryEditorSheet(context, ref),
              icon: const Icon(Icons.edit),
              label: const Text("Write today's entry"),
            ),
          ],
        ),
      ),
    );
  }
}
