import 'package:flutter_test/flutter_test.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/sms_import/data/models/parsed_sms.dart';

void main() {
  group('ParsedSms', () {
    group('computeId', () {
      test('deterministic for same inputs', () {
        final date = DateTime(2024, 3, 15, 10, 30);
        final id1 = ParsedSms.computeId(date, 500.0, TransactionType.expense);
        final id2 = ParsedSms.computeId(date, 500.0, TransactionType.expense);
        expect(id1, id2);
      });

      test('different for different amounts', () {
        final date = DateTime(2024, 3, 15, 10, 30);
        final id1 = ParsedSms.computeId(date, 500.0, TransactionType.expense);
        final id2 = ParsedSms.computeId(date, 600.0, TransactionType.expense);
        expect(id1, isNot(id2));
      });

      test('different for different types', () {
        final date = DateTime(2024, 3, 15, 10, 30);
        final id1 = ParsedSms.computeId(date, 500.0, TransactionType.expense);
        final id2 = ParsedSms.computeId(date, 500.0, TransactionType.income);
        expect(id1, isNot(id2));
      });

      test('different for different dates', () {
        final id1 = ParsedSms.computeId(DateTime(2024, 3, 15), 500.0, TransactionType.expense);
        final id2 = ParsedSms.computeId(DateTime(2024, 3, 16), 500.0, TransactionType.expense);
        expect(id1, isNot(id2));
      });
    });

    group('effectiveCategoryId', () {
      test('returns selectedCategoryId when set', () {
        final sms = ParsedSms(
          smsId: 'test',
          sender: 'HDFCBK',
          date: DateTime.now(),
          amount: 500,
          type: TransactionType.expense,
          suggestedCategoryId: 1,
          selectedCategoryId: 2,
        );
        expect(sms.effectiveCategoryId, 2);
      });

      test('falls back to suggestedCategoryId', () {
        final sms = ParsedSms(
          smsId: 'test',
          sender: 'HDFCBK',
          date: DateTime.now(),
          amount: 500,
          type: TransactionType.expense,
          suggestedCategoryId: 1,
        );
        expect(sms.effectiveCategoryId, 1);
      });

      test('returns null when neither set', () {
        final sms = ParsedSms(
          smsId: 'test',
          sender: 'HDFCBK',
          date: DateTime.now(),
          amount: 500,
          type: TransactionType.expense,
        );
        expect(sms.effectiveCategoryId, isNull);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated field', () {
        final original = ParsedSms(
          smsId: 'test',
          sender: 'HDFCBK',
          date: DateTime.now(),
          amount: 500,
          type: TransactionType.expense,
          selected: true,
        );

        final copy = original.copyWith(selected: false);
        expect(copy.selected, false);
        expect(original.selected, true); // original unchanged
        expect(copy.smsId, original.smsId);
        expect(copy.amount, original.amount);
      });

      test('preserves all fields when no changes', () {
        final original = ParsedSms(
          smsId: 'test',
          sender: 'HDFCBK',
          date: DateTime(2024, 1, 1),
          amount: 500,
          type: TransactionType.expense,
          accountLast4: '1234',
          merchant: 'Swiggy',
          suggestedCategoryId: 1,
          selectedCategoryId: 2,
          selectedAccountId: 3,
          selected: true,
        );

        final copy = original.copyWith();
        expect(copy.smsId, 'test');
        expect(copy.sender, 'HDFCBK');
        expect(copy.amount, 500);
        expect(copy.type, TransactionType.expense);
        expect(copy.accountLast4, '1234');
        expect(copy.merchant, 'Swiggy');
        expect(copy.suggestedCategoryId, 1);
        expect(copy.selectedCategoryId, 2);
        expect(copy.selectedAccountId, 3);
        expect(copy.selected, true);
      });
    });
  });
}
