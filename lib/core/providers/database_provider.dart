import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/backup_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});
