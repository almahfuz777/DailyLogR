// lib/screens/dashboard_screen.dart
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/today_entry_card.dart';
import 'package:dailylogr/widgets/write_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailylogr/providers/journal_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider);

    final todayKey = DayKey.of(DayKey.normalize(DateTime.now()));

    // Find today's entry in the list
    final todayEntry = entries.where((e) {
      return DayKey.of(DayKey.normalize(e.date)) == todayKey;
    }).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: todayEntry == null
          ? const WritePromptCard()
          : TodayEntryCard(entry: todayEntry),
    );
  }
}
