// lib/widgets/dashboard_entry_carousel.dart
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:flutter/material.dart';

/// Carousel item
class CarouselItem {
  final JournalEntry? entry;  // Existing entry for this day
  final DateTime date;  // Normalized calendar date
  final bool isToday;  // Whether this card represents today

  /// Creates one day card for the dashboard carousel.
  const CarouselItem({this.entry, required this.date, required this.isToday});

  /// Whether this day has a saved journal entry.
  bool get hasEntry => entry != null;
}

/// Builds dashboard carousel items from journal entries.
class DashboardCarouselItems {
  const DashboardCarouselItems._();

  /// Returns a descending timeline with empty cards inside edit window.
  static List<CarouselItem> fromEntries(List<JournalEntry> entries) {
    final today = DayKey.normalize(DateTime.now());
    final editWindowStart = DayKey.editWindowStart;
    final entriesByDay = {
      for (final entry in entries)
        if (!DayKey.normalize(entry.date).isAfter(today))
          DayKey.of(DayKey.normalize(entry.date)): entry,
    };

    final editableDayCount = today.difference(editWindowStart).inDays + 1;
    final editableItems = List.generate(editableDayCount, (index) {
      final date = today.subtract(Duration(days: index));
      final entry = entriesByDay[DayKey.of(date)];
      return CarouselItem(entry: entry, date: date, isToday: index == 0);
    });

    final olderEntries = entries.where((entry) {
      final date = DayKey.normalize(entry.date);
      return date.isBefore(editWindowStart) && !date.isAfter(today);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return [
      ...editableItems,
      ...olderEntries.map(
        (entry) => CarouselItem(
          entry: entry,
          date: DayKey.normalize(entry.date),
          isToday: false,
        ),
      ),
    ];
  }
}

class DashboardEntryCarouselController {
  void Function(int)? _animateToPage;

  void animateToPage(int index) {
    _animateToPage?.call(index);
  }

  void _attach(void Function(int) animateToPage) {
    _animateToPage = animateToPage;
  }

  void _detach() {
    _animateToPage = null;
  }
}

/// A layered card carousel with depth/scale effects. Adjacent cards are partially visible, scaled down, and faded to create a clear "swipeable deck" visual.
class DashboardEntryCarousel extends StatefulWidget {
  final List<CarouselItem> items;
  final DashboardEntryCarouselController? controller;
  final void Function(CarouselItem item) onCardTap;
  final void Function(int index)? onPageChanged;

  const DashboardEntryCarousel({
    super.key,
    required this.items,
    this.controller,
    required this.onCardTap,
    this.onPageChanged,
  });

  @override
  State<DashboardEntryCarousel> createState() => _DashboardEntryCarouselState();
}

class _DashboardEntryCarouselState extends State<DashboardEntryCarousel> {
  static const double _viewportFraction = 0.74;
  late PageController _controller;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _viewportFraction);
    _controller.addListener(_onScroll);
    widget.controller?._attach((index) {
      if (_controller.hasClients) {
        _controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _currentPage = _controller.page ?? 0;
    });
  }

  void _goToToday() {
    if (widget.controller != null) {
      widget.controller!.animateToPage(0);
    } else {
      _controller.animateToPage(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showTodayButton = _currentPage > 0.35;
    final activeIndex = _currentPage.round().clamp(0, widget.items.length - 1);

    return Column(
      children: [
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: _BehindCardPreview(
                    item: activeIndex < widget.items.length - 1
                        ? widget.items[activeIndex + 1]
                        : null,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: _BehindCardPreview(
                    item: activeIndex > 0
                        ? widget.items[activeIndex - 1]
                        : null,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
              PageView.builder(
                controller: _controller,
                itemCount: widget.items.length,
                reverse: true,
                onPageChanged: widget.onPageChanged,
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final page = _controller.hasClients
                        ? _controller.page ?? _currentPage
                        : _currentPage;
                    final signedDistance = (page - index).clamp(-1.0, 1.0);
                    final distance = signedDistance.abs();
                    final scale = 1.0 - (distance * 0.10);
                    final yOffset = distance * 20.0;

                    return Transform.translate(
                      offset: Offset(0, yOffset),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: index == activeIndex ? 1 : 0,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _CarouselCard(
                    item: widget.items[index],
                    onTap: () => widget.onCardTap(widget.items[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: AnimatedScale(
                scale: showTodayButton ? 1 : 0.92,
                duration: const Duration(milliseconds: 180),
                child: AnimatedOpacity(
                  opacity: showTodayButton ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !showTodayButton,
                    child: FilledButton.tonalIcon(
                      onPressed: _goToToday,
                      label: const Text('Jump to today'),
                      icon: const Icon(Icons.arrow_circle_right),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card Widgets ────────────────────────────────────────────────────────────

class _BehindCardPreview extends StatelessWidget {
  final CarouselItem? item;
  final Alignment alignment;

  const _BehindCardPreview({required this.item, required this.alignment});

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    if (item == null) return const SizedBox.shrink();

    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 0.68,
        heightFactor: 0.92,
        child: Transform.translate(
          offset: Offset(alignment.x * 42, 18),
          child: Transform.scale(
            scale: 0.90,
            child: Opacity(
              opacity: 0.72,
              child: _CarouselCard(item: item, onTap: () {}),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final CarouselItem item;
  final VoidCallback onTap;

  const _CarouselCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: entry != null
          ? _JournalCard(entry: entry, isToday: item.isToday, onTap: onTap)
          : item.isToday
          ? _TodayPromptCard(date: item.date, onTap: onTap)
          : _EmptyDayCard(date: item.date, onTap: onTap),
    );
  }
}

/// Journal entry summary card.
class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final bool isToday;
  final VoidCallback onTap;

  const _JournalCard({
    required this.entry,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final hasTitle = entry.title?.trim().isNotEmpty ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 280;
        final padding = isCompact ? 16.0 : 24.0;

        return Card(
          elevation: isToday ? 8 : 3,
          shadowColor: color.shadow.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isToday
                  ? color.primary.withValues(alpha: 0.24)
                  : color.outlineVariant.withValues(alpha: 0.6),
              width: isToday ? 1.5 : 1.0,
            ),
          ),
          color: isToday ? color.primaryContainer : color.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isToday)
                    Text(
                      "Today's Entry",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                  SizedBox(height: isCompact ? 2 : 4),
                  Text(
                    DayKey.ofLong(entry.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? color.onPrimaryContainer
                          : color.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 16),

                  if (hasTitle) ...[
                    Text(
                      entry.title!.trim(),
                      maxLines: isCompact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? color.onPrimaryContainer
                            : color.onSurface,
                      ),
                    ),
                    SizedBox(height: isCompact ? 6 : 8),
                  ],

                  Expanded(
                    child: Text(
                      entry.note.trim(),
                      maxLines: isCompact ? 4 : 6,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isToday
                            ? color.onPrimaryContainer.withValues(alpha: 0.85)
                            : color.onSurface.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                  ),

                  if (entry.adjective != null || entry.rating != null) ...[
                    SizedBox(height: isCompact ? 8 : 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (entry.adjective != null &&
                            entry.adjective!.trim().isNotEmpty)
                          _chip(context, entry.adjective!, isToday),
                        if (entry.rating != null)
                          _chip(context, _ratingStars(entry.rating!), isToday),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _ratingStars(int rating) {
    final normalizedRating = rating.clamp(0, 5);
    return '${'★' * normalizedRating}${'☆' * (5 - normalizedRating)}';
  }

  Widget _chip(BuildContext context, String label, bool highlight) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? color.primary.withValues(alpha: 0.12)
            : color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: highlight ? color.primary : color.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Prompt card for an empty today.
class _TodayPromptCard extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _TodayPromptCard({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 280;

        return Card(
          elevation: 8,
          shadowColor: color.shadow.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: color.primary.withValues(alpha: 0.28),
              width: 1.5,
            ),
          ),
          color: color.primaryContainer,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 16 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: isCompact ? 36 : 48,
                    color: color.primary.withValues(alpha: 0.7),
                  ),
                  SizedBox(height: isCompact ? 10 : 16),
                  Text(
                    DayKey.ofLong(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color.onPrimaryContainer.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 12),
                  Text(
                    'How was your day?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                  Flexible(
                    child: Text(
                      "Write today's entry to keep your streak alive.",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 20),
                  FittedBox(
                    child: FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.add),
                      label: const Text("Write today's entry"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _EmptyDayCard({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    
    final today = DayKey.normalize(DateTime.now());
    final isYesterday = date == today.subtract(const Duration(days: 1));
    final title = isYesterday ? 'Catch up on yesterday' : 'Fill in this day';
    final subtitle = isYesterday 
        ? 'You can still log it and protect your streak.' 
        : 'Add a quick note while this date is still editable.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 280;

        return Card(
          elevation: 2,
          shadowColor: color.shadow.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: color.outlineVariant.withValues(alpha: 0.6),
              width: 1.0,
            ),
          ),
          color: color.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DayKey.ofLong(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.event_note_outlined,
                    size: isCompact ? 32 : 40,
                    color: color.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                  SizedBox(height: isCompact ? 10 : 16),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color.onSurface,
                    ),
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                  Flexible(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      child: FilledButton.tonalIcon(
                        onPressed: onTap,
                        icon: const Icon(Icons.add),
                        label: const Text('Add entry'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
