import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/csv_importer.dart';

void main() {
  late AppDatabase db;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.categories).get(); // trigger seed
  });

  tearDown(() => db.close());

  Future<File> writeTempCsv(String content) async {
    final dir = Directory.systemTemp.createTempSync('csv_test');
    final file = File('${dir.path}/test.csv');
    await file.writeAsString(content);
    return file;
  }

  group('CsvImporter error reporting', () {
    test('collects errors for rows with too few columns', () async {
      final file = await writeTempCsv(
        'Date,Type,Amount,Category,Account\r\n'
        'bad,,\r\n',
      );
      final result = await CsvImporter(db).importFromFile(file);
      // 'bad,,\r\n' parses as [bad, , ] which has length 3 but invalid date
      expect(result.skipped, 1);
      expect(result.errors.length, 1);
      expect(result.errors.first.rowNumber, 2);
      expect(result.errors.first.reason, contains('Invalid date'));
    });

    test('collects errors for invalid dates', () async {
      final file = await writeTempCsv(
        'Date,Type,Amount\r\n'
        'not-a-date,expense,100\r\n',
      );
      final result = await CsvImporter(db).importFromFile(file);
      expect(result.skipped, 1);
      expect(result.errors.length, 1);
      expect(result.errors.first.rowNumber, 2);
      expect(result.errors.first.reason, contains('Invalid date'));
    });

    test('collects errors for invalid amounts', () async {
      final file = await writeTempCsv(
        'Date,Type,Amount\r\n'
        '2024-01-15,expense,abc\r\n'
        '2024-01-15,expense,-5\r\n',
      );
      final result = await CsvImporter(db).importFromFile(file);
      expect(result.skipped, 2);
      expect(result.errors.length, 2);
      expect(result.errors[0].rowNumber, 2);
      expect(result.errors[0].reason, contains('Invalid amount'));
      expect(result.errors[1].rowNumber, 3);
    });

    test('successfully imports valid rows and reports errors for bad ones', () async {
      final file = await writeTempCsv(
        'Date,Type,Amount,Category,Account\r\n'
        '2024-01-15,expense,50,Food,Cash\r\n'
        'bad-date,expense,100,Food,Cash\r\n'
        '2024-01-16,expense,25,Food,Cash\r\n',
      );
      final result = await CsvImporter(db).importFromFile(file);
      expect(result.imported, 2);
      expect(result.skipped, 1);
      expect(result.errors.length, 1);
      expect(result.errors.first.rowNumber, 3);
    });
  });
}
