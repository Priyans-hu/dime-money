import 'package:flutter_test/flutter_test.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/sms_import/data/services/sms_parser_service.dart';
import 'package:dime_money/features/sms_import/data/services/sms_reader_service.dart';

void main() {
  late SmsParserService parser;

  setUp(() {
    parser = SmsParserService();
  });

  SmsMessage _msg(String body, {String sender = 'HDFCBK'}) {
    return SmsMessage(sender: sender, body: body, date: DateTime(2024, 3, 15, 10, 30));
  }

  group('SmsParserService', () {
    group('amount extraction', () {
      test('parses Rs. format', () {
        final result = parser.parse(_msg('Rs.500.00 debited from your A/C'));
        expect(result, isNotNull);
        expect(result!.amount, 500.0);
      });

      test('parses INR format', () {
        final result = parser.parse(_msg('INR 1,234.50 debited from A/C XX1234'));
        expect(result, isNotNull);
        expect(result!.amount, 1234.50);
      });

      test('parses rupee symbol', () {
        final result = parser.parse(_msg('\u20B92,000 debited from A/C'));
        expect(result, isNotNull);
        expect(result!.amount, 2000.0);
      });

      test('parses amount with commas', () {
        final result = parser.parse(_msg('Rs.1,00,000.00 credited to your A/C'));
        expect(result, isNotNull);
        expect(result!.amount, 100000.0);
      });

      test('returns null when no amount', () {
        final result = parser.parse(_msg('Your account login was successful'));
        expect(result, isNull);
      });
    });

    group('transaction type detection', () {
      test('detects debit/expense keywords', () {
        final result = parser.parse(_msg('Rs.500 debited from your A/C XX1234'));
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
      });

      test('detects credit/income keywords', () {
        final result = parser.parse(_msg('Rs.10,000 credited to your A/C XX5678'));
        expect(result, isNotNull);
        expect(result!.type, TransactionType.income);
      });

      test('detects spent keyword as expense', () {
        final result = parser.parse(_msg('Rs.250 spent at Swiggy via A/C XX1234'));
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
      });

      test('detects refund as income', () {
        final result = parser.parse(_msg('Refund of Rs.500 credited to your A/C'));
        expect(result, isNotNull);
        expect(result!.type, TransactionType.income);
      });

      test('returns null when no type keyword', () {
        final result = parser.parse(_msg('Rs.500 balance in your A/C'));
        expect(result, isNull);
      });

      test('when both debit and credit found, uses first occurrence', () {
        // "debited" appears before "credited"
        final result = parser.parse(_msg('Rs.500 debited; Rs.10 credited cashback'));
        expect(result, isNotNull);
        expect(result!.type, TransactionType.expense);
      });
    });

    group('account extraction', () {
      test('extracts last 4 digits from A/C XX1234', () {
        final result = parser.parse(_msg('Rs.500 debited from A/C XX1234'));
        expect(result, isNotNull);
        expect(result!.accountLast4, '1234');
      });

      test('extracts last 4 digits from account**5678', () {
        final result = parser.parse(_msg('Rs.500 debited from account**5678'));
        expect(result, isNotNull);
        expect(result!.accountLast4, '5678');
      });

      test('returns null accountLast4 when no account pattern', () {
        final result = parser.parse(_msg('Rs.500 debited'));
        expect(result, isNotNull);
        expect(result!.accountLast4, isNull);
      });
    });

    group('merchant extraction', () {
      test('extracts merchant after "to"', () {
        final result = parser.parse(_msg('Rs.500 debited to Swiggy on 15-Mar'));
        expect(result, isNotNull);
        expect(result!.merchant, isNotNull);
        expect(result!.merchant!.toLowerCase(), contains('swiggy'));
      });

      test('extracts merchant after "at"', () {
        final result = parser.parse(_msg('Rs.250 spent at Amazon.in ref 123'));
        expect(result, isNotNull);
        expect(result!.merchant, isNotNull);
      });

      test('returns null merchant when no pattern', () {
        final result = parser.parse(_msg('Rs.500 debited from A/C XX1234'));
        expect(result!.merchant, isNull);
      });
    });

    group('filtering', () {
      test('skips OTP messages', () {
        final result = parser.parse(_msg('Your OTP for transaction is 123456. Rs.500'));
        expect(result, isNull);
      });

      test('skips promotional messages', () {
        final result = parser.parse(_msg('Congratulations! Win cashback up to Rs.500'));
        expect(result, isNull);
      });

      test('skips messages without amount', () {
        final result = parser.parse(_msg('Login successful from new device'));
        expect(result, isNull);
      });
    });

    group('parseAll', () {
      test('parses multiple messages and filters nulls', () {
        final messages = [
          _msg('Rs.500 debited from A/C XX1234'),
          _msg('Your OTP is 123456'),
          _msg('Rs.1000 credited to your A/C XX5678'),
        ];

        final results = parser.parseAll(messages);
        expect(results, hasLength(2));
        expect(results[0].type, TransactionType.expense);
        expect(results[1].type, TransactionType.income);
      });

      test('returns empty for all-invalid messages', () {
        final messages = [
          _msg('Your OTP is 123456'),
          _msg('Login successful'),
        ];
        expect(parser.parseAll(messages), isEmpty);
      });
    });

    group('smsId generation', () {
      test('same date+amount+type produce same id', () {
        final msg = _msg('Rs.500 debited from A/C');
        final r1 = parser.parse(msg);
        final r2 = parser.parse(msg);
        expect(r1!.smsId, r2!.smsId);
      });

      test('different amounts produce different ids', () {
        final r1 = parser.parse(_msg('Rs.500 debited from A/C'));
        final r2 = parser.parse(_msg('Rs.600 debited from A/C'));
        expect(r1!.smsId, isNot(r2!.smsId));
      });
    });
  });
}
