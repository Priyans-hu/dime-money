import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/recurring/data/repositories/recurring_repository.dart';

/// Pre-release: Recurring rule processing tests.
void main() {
  late AppDatabase db;
  late RecurringRepository recurringRepo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recurringRepo = RecurringRepository(db);
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('Recurring rule CRUD', () {
    test('insert and retrieve recurring rule', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      final id = await recurringRepo.insert(
        type: TransactionType.expense,
        amount: 15,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        note: 'Netflix',
        recurrence: RecurrenceType.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
      );

      expect(id, greaterThan(0));

      final rules = await recurringRepo.getActive();
      expect(rules.length, 1);
      expect(rules.first.note, 'Netflix');
      expect(rules.first.recurrence, RecurrenceType.monthly);
    });

    test('delete rule removes it', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      final id = await recurringRepo.insert(
        type: TransactionType.expense,
        amount: 10,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        recurrence: RecurrenceType.daily,
        startDate: DateTime.now(),
      );

      await recurringRepo.deleteById(id);
      final rules = await recurringRepo.getActive();
      expect(rules, isEmpty);
    });
  });

  group('Rule processing', () {
    test('daily rule generates transactions for past days', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      await recurringRepo.insert(
        type: TransactionType.expense,
        amount: 5,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        note: 'Daily coffee',
        recurrence: RecurrenceType.daily,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      final generated = await recurringRepo.processRules();
      expect(generated, greaterThanOrEqualTo(4)); // at least 4-5 days

      final txns = await db.select(db.transactions).get();
      expect(txns.length, generated);
      expect(txns.every((t) => t.amount == 5), isTrue);
      expect(txns.every((t) => t.note == 'Daily coffee'), isTrue);
    });

    test('weekly rule generates correct count', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      await recurringRepo.insert(
        type: TransactionType.expense,
        amount: 30,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        note: 'Weekly groceries',
        recurrence: RecurrenceType.weekly,
        startDate: DateTime.now().subtract(const Duration(days: 21)),
      );

      final generated = await recurringRepo.processRules();
      expect(generated, greaterThanOrEqualTo(2)); // 21 days / 7 = 3 weeks
      expect(generated, lessThanOrEqualTo(3));
    });

    test('monthly rule from 2 months ago generates 2 transactions', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      await recurringRepo.insert(
        type: TransactionType.expense,
        amount: 99,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        note: 'Subscription',
        recurrence: RecurrenceType.monthly,
        startDate: DateTime(now.year, now.month - 3, now.day),
      );

      final generated = await recurringRepo.processRules();
      expect(generated, greaterThanOrEqualTo(2));
    });

    test('income recurring rule generates income transactions', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      await recurringRepo.insert(
        type: TransactionType.income,
        amount: 5000,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        note: 'Salary',
        recurrence: RecurrenceType.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
      );

      await recurringRepo.processRules();

      final txns = await db.select(db.transactions).get();
      expect(txns.every((t) => t.type == TransactionType.income), isTrue);
      expect(txns.every((t) => t.amount == 5000), isTrue);
    });

    test('expired rule (endDate passed) does not generate', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      await recurringRepo.insert(
        type: TransactionType.expense,
        amount: 10,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        recurrence: RecurrenceType.daily,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().subtract(const Duration(days: 10)),
      );

      final generated = await recurringRepo.processRules();
      expect(generated, 0);
    });

    test('processing twice does not duplicate', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      await recurringRepo.insert(
        type: TransactionType.expense,
        amount: 10,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        recurrence: RecurrenceType.daily,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      final first = await recurringRepo.processRules();
      final second = await recurringRepo.processRules();

      expect(first, greaterThan(0));
      expect(second, 0, reason: 'Second run should not generate duplicates');
    });

    test('generated transactions link back to rule via recurringRuleId',
        () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      final ruleId = await recurringRepo.insert(
        type: TransactionType.expense,
        amount: 15,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        recurrence: RecurrenceType.daily,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      await recurringRepo.processRules();

      final txns = await db.select(db.transactions).get();
      expect(txns.isNotEmpty, isTrue);
      expect(txns.every((t) => t.recurringRuleId == ruleId), isTrue);
    });
  });
}
