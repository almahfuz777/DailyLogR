// lib/screens/entries_screen.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/entry_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:dailylogr/widgets/empty_state.dart';
import 'package:dailylogr/screens/trash_screen.dart';
import 'package:dailylogr/widgets/entry_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/journal_provider.dart';
import 'package:dailylogr/providers/journal_filters_provider.dart';
import 'package:dailylogr/widgets/search_bar.dart';

final selectedEntriesProvider = StateProvider<Set<String>>((ref) => {});

class EntriesScreen extends ConsumerWidget {
  const EntriesScreen({super.key});

  Widget _buildNoResultsState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: color.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No entries found',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We couldn't find any entries matching your search query or filters.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(selectedMoodProvider.notifier).state = null;
                  ref.read(selectedRatingProvider.notifier).state = null;
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider);
    final selectedEntries = ref.watch(selectedEntriesProvider);

    if (entries.isEmpty) {
      return const EmptyState();
    }

    final searchQuery = ref.watch(searchQueryProvider);
    final selectedMood = ref.watch(selectedMoodProvider);
    final selectedRating = ref.watch(selectedRatingProvider);

    final filteredEntries = entries.where((e) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = e.title?.toLowerCase().contains(query) ?? false;
        final matchesNote = e.note.toLowerCase().contains(query);
        if (!matchesTitle && !matchesNote) {
          return false;
        }
      }

      if (selectedMood != null) {
        if (e.adjective == null || e.adjective != selectedMood) {
          return false;
        }
      }

      if (selectedRating != null) {
        if (e.rating != selectedRating) {
          return false;
        }
      }

      return true;
    }).toList();

    return Column(
      children: [
        const EntriesSearchBar(),
        Expanded(
          child: filteredEntries.isEmpty
              ? _buildNoResultsState(context, ref)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: filteredEntries.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = filteredEntries[i];
                    final id = DayKey.of(DayKey.normalize(e.date));
                    final isSelected = selectedEntries.contains(id);

                    return EntryTile(
                      key: ValueKey(id),
                      entry: e,
                      isSelected: isSelected,
                      onTap: () {
                        if (selectedEntries.isNotEmpty) {
                          // Selection mode active
                          final notifier = ref.read(selectedEntriesProvider.notifier);
                          if (isSelected) {
                            notifier.state = {...selectedEntries}..remove(id);
                          } else {
                            notifier.state = {...selectedEntries, id};
                          }
                        } else {
                          // Normal mode - edit
                          entryEditorSheet(context, ref, initial: e);
                        }
                      },
                      onLongPress: () {
                        final notifier = ref.read(selectedEntriesProvider.notifier);
                        if (isSelected) {
                          notifier.state = {...selectedEntries}..remove(id);
                        } else {
                          notifier.state = {...selectedEntries, id};
                        }
                      },
                    );
                  },
                ),
        ),
        
        // Anchored bottom button
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Recently Deleted'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}
