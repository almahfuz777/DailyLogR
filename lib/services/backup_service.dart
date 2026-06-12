// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/hive_service.dart';
import '../providers/journal_provider.dart';
import '../utils/date_helper.dart';

class BackupService {
  /// Exports all journal entries from Hive to a JSON file.
  static Future<void> exportBackup(BuildContext context) async {
    try {
      final entries = HiveService.journalBox.values.toList();
      if (entries.isEmpty) {
        _showSnack(context, 'No journal entries found to export.');
        return;
      }

      // Convert to JSON
      final jsonList = entries.map((e) => e.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'dailylogr_backup_$dateStr.json';

      // 1. Try to open the native Save As dialog
      String? outputPath;
      try {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(jsonString),
        );
      } catch (e) {
        debugPrint('FilePicker saveFile failed: $e');
      }

      // 2. If path is returned, write to it (specifically for Desktop)
      if (outputPath != null) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          final file = File(outputPath);
          await file.writeAsString(jsonString);
        }
        if (context.mounted) {
          _showSnack(context, 'Backup saved successfully to local storage.');
        }
        return;
      }

      // 3. Fallback to share sheet on mobile (Android/iOS) if saveFile returns null or fails
      if (Platform.isAndroid || Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);

        final xFile = XFile(file.path, mimeType: 'application/json');
        await Share.shareXFiles(
          [xFile],
          text: 'DailyLogR Backup File',
          subject: 'DailyLogR Backup',
        );
      } else {
        // Desktop user cancelled the save dialog
        if (context.mounted) {
          _showSnack(context, 'Export cancelled.');
        }
      }
    } catch (e) {
      debugPrint('Export backup failed: $e');
      if (context.mounted) {
        _showSnack(context, 'Failed to export backup: $e');
      }
    }
  }

  /// Prompts the user to pick a JSON backup file and merges the entries.
  static Future<void> importBackup(BuildContext context, WidgetRef ref) async {
    bool loadingShown = false;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        // User cancelled picker
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      // Parse JSON
      final List<dynamic> decoded = jsonDecode(content);
      final List<JournalEntry> imported = decoded.map((item) {
        return JournalEntry.fromJson(item as Map<String, dynamic>);
      }).toList();

      if (imported.isEmpty) {
        if (context.mounted) {
          _showSnack(context, 'The selected file does not contain any entries.');
        }
        return;
      }

      // Check for duplicates
      final box = HiveService.journalBox;
      int duplicateCount = 0;
      for (final entry in imported) {
        final key = DayKey.of(DayKey.normalize(entry.date));
        if (box.containsKey(key)) {
          duplicateCount++;
        }
      }

      bool forceOverwrite = false;
      if (duplicateCount > 0) {
        if (!context.mounted) return;
        final shouldOverwrite = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Duplicate Entries Found'),
            content: Text(
              'The backup contains $duplicateCount entries that already exist in the app.\n\n'
              'Do you want to overwrite all existing ones?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel Import'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Overwrite & Import'),
              ),
            ],
          ),
        );

        if (shouldOverwrite != true) {
          // Abort import entirely
          return;
        }
        forceOverwrite = true;
      }

      // Perform import
      if (context.mounted) {
        loadingShown = true;
        _showLoadingDialog(context, 'Importing entries...');
      }

      final importedCount = await ref.read(journalProvider.notifier).importEntries(
        imported,
        forceOverwrite: forceOverwrite,
      );

      if (context.mounted) {
        if (loadingShown) {
          Navigator.pop(context); // Close loading dialog
          loadingShown = false;
        }
        _showSnack(
          context,
          'Successfully imported $importedCount entries.',
        );
      }
    } catch (e) {
      debugPrint('Import backup failed: $e');
      if (context.mounted) {
        if (loadingShown) {
          Navigator.pop(context);
        }
        _showSnack(context, 'Failed to import backup: $e');
      }
    }
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
}
