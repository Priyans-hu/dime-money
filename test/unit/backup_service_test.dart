import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/backup_service.dart';

void main() {
  late AppDatabase db;
  late BackupService backupService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backupService = BackupService(db);
    await db.select(db.categories).get(); // trigger seed
  });

  tearDown(() => db.close());

  group('BackupService', () {
    test('checkIntegrity returns true for healthy database', () async {
      final result = await backupService.checkIntegrity();
      expect(result, true);
    });
  });
}
