import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/sms_import/data/models/parsed_sms.dart';
import 'package:dime_money/features/sms_import/data/services/duplicate_tracker.dart';

void main() {
  late DuplicateTracker tracker;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tracker = DuplicateTracker();
  });

  ParsedSms _makeSms(String id) {
    return ParsedSms(
      smsId: id,
      sender: 'HDFCBK',
      date: DateTime.now(),
      amount: 500,
      type: TransactionType.expense,
    );
  }

  group('DuplicateTracker', () {
    test('filterNew returns all items when no history', () async {
      final items = [_makeSms('a'), _makeSms('b'), _makeSms('c')];
      final result = await tracker.filterNew(items);
      expect(result, hasLength(3));
    });

    test('filterNew removes already-imported items', () async {
      await tracker.markImported(['a', 'b']);
      final items = [_makeSms('a'), _makeSms('b'), _makeSms('c')];
      final result = await tracker.filterNew(items);
      expect(result, hasLength(1));
      expect(result.first.smsId, 'c');
    });

    test('markImported accumulates hashes', () async {
      await tracker.markImported(['a']);
      await tracker.markImported(['b']);
      final items = [_makeSms('a'), _makeSms('b'), _makeSms('c')];
      final result = await tracker.filterNew(items);
      expect(result, hasLength(1));
      expect(result.first.smsId, 'c');
    });

    test('markImported handles empty list', () async {
      await tracker.markImported([]);
      final items = [_makeSms('a')];
      final result = await tracker.filterNew(items);
      expect(result, hasLength(1));
    });

    test('filterNew returns empty for all duplicates', () async {
      await tracker.markImported(['a', 'b']);
      final items = [_makeSms('a'), _makeSms('b')];
      final result = await tracker.filterNew(items);
      expect(result, isEmpty);
    });

    test('persists across tracker instances', () async {
      await tracker.markImported(['a']);

      // New tracker instance reads from same SharedPreferences
      final tracker2 = DuplicateTracker();
      final items = [_makeSms('a'), _makeSms('b')];
      final result = await tracker2.filterNew(items);
      expect(result, hasLength(1));
      expect(result.first.smsId, 'b');
    });
  });
}
