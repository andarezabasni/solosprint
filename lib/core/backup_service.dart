import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'database/activity_database.dart';

class BackupService {
  /// Export all Hive data — share as files via Android Share Sheet.
  static Future<void> exportData(BuildContext context) async {
    try {
      // Get Hive box paths
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/backup');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Copy Hive files to backup folder
      for (final name in ['activities.hive', 'goals.hive', 'daily_steps.hive']) {
        final src = File('${dir.path}/$name');
        if (await src.exists()) {
          await src.copy('${backupDir.path}/$name');
        }
      }

      // Also copy lock files if they contain data (small, but useful for integrity)
      for (final name in ['activities.lock', 'goals.lock', 'daily_steps.lock']) {
        final src = File('${dir.path}/$name');
        if (await src.exists()) {
          await src.copy('${backupDir.path}/$name');
        }
      }

      // Zip or just share the folder
      final files = await backupDir.list().toList();
      final xFiles = files
          .whereType<File>()
          .map((f) => XFile(f.path))
          .toList();

      if (xFiles.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to backup yet.')),
          );
        }
        return;
      }

      await Share.shareXFiles(
        xFiles,
        text: 'SoloSprint Backup — ${DateTime.now().toIso8601String().substring(0, 10)}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  /// Restore data from a selected backup file.
  static Future<void> restoreData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      // Close all boxes before replacing files
      await Hive.close();

      final dir = await getApplicationDocumentsDirectory();

      for (final file in result.files) {
        if (file.path == null) continue;
        final name = file.name;
        // Only restore recognized hive files
        if (name.endsWith('.hive') || name.endsWith('.lock')) {
          await File(file.path!).copy('${dir.path}/$name');
        }
      }

      // Reopen boxes
      await ActivityDatabase.init();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data restored! Please restart the app.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Reopen boxes even on error
      await ActivityDatabase.init();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }
}
