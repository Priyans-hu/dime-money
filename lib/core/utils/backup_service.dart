import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dime_money/core/database/app_database.dart';

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  static const _lastBackupKey = 'last_backup_epoch';
  static const _backupDir = 'backups';
  static const _maxBackups = 3;
  static const _backupIntervalDays = 7;

  /// Run auto-backup if 7+ days since last backup. Keep last 3 files.
  /// Set [force] to true to bypass the time check.
  Future<void> autoBackup({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEpoch = prefs.getInt(_lastBackupKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceLast =
          (now - lastEpoch) / (1000 * 60 * 60 * 24);

      if (!force && daysSinceLast < _backupIntervalDays) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final backupFolder = Directory(p.join(docsDir.path, _backupDir));
      if (!backupFolder.existsSync()) {
        backupFolder.createSync(recursive: true);
      }

      // Source DB file
      final dbFile = File(p.join(docsDir.path, 'dime_money.sqlite'));
      if (!dbFile.existsSync()) return;

      // Copy with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile =
          File(p.join(backupFolder.path, 'dime_money_$timestamp.sqlite'));
      await dbFile.copy(backupFile.path);

      // Prune old backups — keep last N
      final backups = backupFolder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sqlite'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path)); // newest first

      if (backups.length > _maxBackups) {
        for (final old in backups.sublist(_maxBackups)) {
          await old.delete();
        }
      }

      await prefs.setInt(_lastBackupKey, now);
    } catch (e) {
      debugPrint('BackupService.autoBackup: $e');
    }
  }

  /// Run PRAGMA integrity_check on the database.
  Future<bool> checkIntegrity() async {
    try {
      final result =
          await _db.customSelect('PRAGMA integrity_check').getSingle();
      return result.read<String>('integrity_check') == 'ok';
    } catch (e) {
      debugPrint('BackupService.checkIntegrity: $e');
      return false;
    }
  }

  /// Replace DB file with a backup. For future use — not wired to UI yet.
  Future<void> restoreFromBackup(File backupFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, 'dime_money.sqlite'));
    await backupFile.copy(dbFile.path);
  }
}
