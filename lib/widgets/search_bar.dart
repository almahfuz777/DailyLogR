// lib/widgets/search_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/journal_filters_provider.dart';
import 'package:dailylogr/providers/journal_provider.dart';

class EntriesSearchBar extends ConsumerStatefulWidget {
  const EntriesSearchBar({super.key});

  @override
  ConsumerState<EntriesSearchBar> createState() => _EntriesSearchBarState();
}

class _EntriesSearchBarState extends ConsumerState<EntriesSearchBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMoodFilterSheet(List<String> loggedMoods) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final selectedMood = ref.read(selectedMoodProvider);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Mood',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (loggedMoods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No moods logged in your entries yet.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: loggedMoods.map((mood) {
                      final isSelected = selectedMood == mood;
                      return ChoiceChip(
                        label: Text(mood),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(selectedMoodProvider.notifier).state = selected ? mood : null;
                          Navigator.pop(ctx);
                        },
                        showCheckmark: false,
                        selectedColor: color.primaryContainer,
                      );
                    }).toList(),
                  ),
                if (selectedMood != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(selectedMoodProvider.notifier).state = null;
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear Mood Filter'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRatingFilterSheet() {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final selectedRating = ref.read(selectedRatingProvider);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Rating',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final stars = i + 1;
                    final isSelected = selectedRating == stars;
                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedRatingProvider.notifier).state = isSelected ? null : stars;
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Icon(
                              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 44,
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$stars ★',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? color.primary : color.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                if (selectedRating != null) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(selectedRatingProvider.notifier).state = null;
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear Rating Filter'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final searchQuery = ref.watch(searchQueryProvider);
    final selectedMood = ref.watch(selectedMoodProvider);
    final selectedRating = ref.watch(selectedRatingProvider);
    final showFilters = ref.watch(showFiltersProvider);

    final entries = ref.watch(journalProvider);
    final loggedMoods = entries
        .map((e) => e.adjective)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
    }

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            padding: EdgeInsets.zero,
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search entries by title or details...',
                hintStyle: TextStyle(
                  color: color.onSurfaceVariant.withValues(alpha: 0.65),
                ),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: color.onSurfaceVariant),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        showFilters ? Icons.filter_alt_off : Icons.filter_alt_outlined,
                        color: showFilters ? color.primary : color.onSurfaceVariant,
                      ),
                      onPressed: () {
                        ref.read(showFiltersProvider.notifier).state = !showFilters;
                      },
                      tooltip: 'Toggle filters',
                    ),
                  ],
                ),
              ),
              style: TextStyle(color: color.onSurface),
              onChanged: (val) {
                ref.read(searchQueryProvider.notifier).state = val;
              },
            ),
          ),
          const SizedBox(height: 8),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: showFilters
                ? Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text(selectedMood ?? 'Mood'),
                            selected: selectedMood != null,
                            onSelected: (_) => _showMoodFilterSheet(loggedMoods),
                            selectedColor: color.primaryContainer,
                            labelStyle: TextStyle(
                              color: selectedMood != null ? color.onPrimaryContainer : color.onSurfaceVariant,
                              fontWeight: selectedMood != null ? FontWeight.bold : FontWeight.normal,
                            ),
                            avatar: selectedMood != null
                                ? null
                                : Icon(Icons.emoji_emotions_outlined, size: 18, color: color.onSurfaceVariant),
                            showCheckmark: false,
                          ),
                          const SizedBox(width: 8),

                          FilterChip(
                            label: Text(selectedRating != null ? '⭐ $selectedRating/5' : 'Rating'),
                            selected: selectedRating != null,
                            onSelected: (_) => _showRatingFilterSheet(),
                            selectedColor: color.primaryContainer,
                            labelStyle: TextStyle(
                              color: selectedRating != null ? color.onPrimaryContainer : color.onSurfaceVariant,
                              fontWeight: selectedRating != null ? FontWeight.bold : FontWeight.normal,
                            ),
                            avatar: selectedRating != null
                                ? null
                                : Icon(Icons.star_outline_rounded, size: 18, color: color.onSurfaceVariant),
                            showCheckmark: false,
                          ),
                          
                          if (searchQuery.isNotEmpty || selectedMood != null || selectedRating != null) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                                ref.read(selectedMoodProvider.notifier).state = null;
                                ref.read(selectedRatingProvider.notifier).state = null;
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Reset'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
