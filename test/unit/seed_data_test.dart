import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/utils/seed_data.dart';
import 'package:dime_money/features/budgets/data/repositories/budget_repository.dart';

void main() {
  late AppDatabase db;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // Mock home_widget channel to prevent MissingPluginException
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('seedDummyData', () {
    test('inserts 25 transactions', () async {
      final count = await seedDummyData(db);
      expect(count, 25);

      final txns = await db.select(db.transactions).get();
      expect(txns.length, 25);
    });

    test('creates a mix of expense, income, and transfer types', () async {
      await seedDummyData(db);
      final txns = await db.select(db.transactions).get();

      final expenses =
          txns.where((t) => t.type == TransactionType.expense).toList();
      final incomes =
          txns.where((t) => t.type == TransactionType.income).toList();
      final transfers =
          txns.where((t) => t.type == TransactionType.transfer).toList();

      expect(expenses.length, 18);
      expect(incomes.length, 5);
      expect(transfers.length, 2);
    });

    test('creates 2 budgets for current month', () async {
      await seedDummyData(db);
      final now = DateTime.now();
      final budgetRepo = BudgetRepository(db);
      final budgets = await budgetRepo.getForMonth(now.year, now.month);
      expect(budgets.length, 2);
    });

    test('all transactions have valid dates within past 30 days', () async {
      await seedDummyData(db);
      final txns = await db.select(db.transactions).get();
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 31));

      for (final txn in txns) {
        expect(txn.date.isAfter(thirtyDaysAgo), isTrue,
            reason: 'Transaction date ${txn.date} should be within 30 days');
        expect(txn.date.isBefore(now.add(const Duration(days: 1))), isTrue);
      }
    });

    test('all expenses have non-null categoryId', () async {
      await seedDummyData(db);
      final txns = await db.select(db.transactions).get();
      final expenses =
          txns.where((t) => t.type == TransactionType.expense).toList();

      for (final e in expenses) {
        expect(e.categoryId, isNotNull);
      }
    });

    test('all transactions have positive amounts', () async {
      await seedDummyData(db);
      final txns = await db.select(db.transactions).get();

      for (final txn in txns) {
        expect(txn.amount, greaterThan(0));
      }
    });

    test('creates second account if only one exists', () async {
      final accountsBefore = await db.select(db.accounts).get();
      expect(accountsBefore.length, 1); // Only default Cash

      await seedDummyData(db);

      final accountsAfter = await db.select(db.accounts).get();
      expect(accountsAfter.length, 2);
      expect(accountsAfter[1].name, 'Bank');
    });

    test('returns 0 when no categories exist', () async {
      // Create a fresh db without default seeds
      final emptyDb = AppDatabase.forTesting(NativeDatabase.memory());
      // Delete all categories
      await emptyDb.delete(emptyDb.categories).go();

      final count = await seedDummyData(emptyDb);
      expect(count, 0);

      await emptyDb.close();
    });
  });
}
