import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  group('Migration scaffolding', () {
    test('schema v1 creates successfully with in-memory DB', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // Trigger migration by querying
      final categories = await db.select(db.categories).get();
      expect(categories, isNotEmpty); // seeded defaults
      await db.close();
    });

    test('PRAGMA foreign_keys is ON after open', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // Trigger beforeOpen
      await db.select(db.categories).get();

      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.read<int>('foreign_keys'), 1);
      await db.close();
    });
  });
}
