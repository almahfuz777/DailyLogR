// lib/screens/dashboard_screen.dart
import 'package:dailylogr/models/journal_entry.dart';
import 'package:dailylogr/services/hive_service.dart';
import 'package:dailylogr/utils/date_helper.dart';
import 'package:dailylogr/widgets/today_entry_card.dart';
import 'package:dailylogr/widgets/write_prompt_card.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<JournalEntry>>(
      valueListenable: HiveService.journalBox.listenable(),
      builder: (context, box, _) {
        final todayKey = DayKey.of(DayKey.normalize(DateTime.now()));
        final todayEntry = box.get(todayKey);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: todayEntry == null
              ? const WritePromptCard()
              : TodayEntryCard(entry: todayEntry),
        );
      },
    );
  }
}
