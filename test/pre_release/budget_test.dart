import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/budgets/data/repositories/budget_repository.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';

/// Pre-release: Budget CRUD + spend tracking tests.
void main() {
  late AppDatabase db;
  late BudgetRepository budgetRepo;
  late TransactionRepository txnRepo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    budgetRepo = BudgetRepository(db);
    txnRepo = TransactionRepository(db);
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('Budget CRUD', () {
    test('create budget for a category', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      await budgetRepo.upsert(
        categoryId: categories.first.id,
        amount: 500,
        year: now.year,
        month: now.month,
      );

      final budgets = await budgetRepo.getForMonth(now.year, now.month);
      expect(budgets.length, 1);
      expect(budgets.first.amount, 500);
      expect(budgets.first.categoryId, categories.first.id);
    });

    test('upsert updates existing budget amount', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();
      final catId = categories.first.id;

      await budgetRepo.upsert(
        categoryId: catId,
        amount: 500,
        year: now.year,
        month: now.month,
      );

      await budgetRepo.upsert(
        categoryId: catId,
        amount: 750,
        year: now.year,
        month: now.month,
      );

      final budgets = await budgetRepo.getForMonth(now.year, now.month);
      expect(budgets.length, 1);
      expect(budgets.first.amount, 750);
    });

    test('different months have separate budgets', () async {
      final categories = await db.select(db.categories).get();
      final catId = categories.first.id;

      await budgetRepo.upsert(
          categoryId: catId, amount: 500, year: 2026, month: 1);
      await budgetRepo.upsert(
          categoryId: catId, amount: 300, year: 2026, month: 2);

      final jan = await budgetRepo.getForMonth(2026, 1);
      final feb = await budgetRepo.getForMonth(2026, 2);

      expect(jan.length, 1);
      expect(jan.first.amount, 500);
      expect(feb.length, 1);
      expect(feb.first.amount, 300);
    });

    test('delete budget removes it', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      await budgetRepo.upsert(
        categoryId: categories.first.id,
        amount: 500,
        year: now.year,
        month: now.month,
      );

      final budgets = await budgetRepo.getForMonth(now.year, now.month);
      await budgetRepo.deleteById(budgets.first.id);

      final after = await budgetRepo.getForMonth(now.year, now.month);
      expect(after, isEmpty);
    });

    test('multiple category budgets in same month', () async {
      final categories = await db.select(db.categories).get();
      final now = DateTime.now();

      for (int i = 0; i < 4 && i < categories.length; i++) {
        await budgetRepo.upsert(
          categoryId: categories[i].id,
          amount: (i + 1) * 100.0,
          year: now.year,
          month: now.month,
        );
      }

      final budgets = await budgetRepo.getForMonth(now.year, now.month);
      expect(budgets.length, 4);
    });
  });

  group('Budget vs actual spending', () {
    test('spending within budget', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final now = DateTime.now();
      final catId = categories.first.id;
      final accountId = accounts.first.id;

      // Set budget of 500
      await budgetRepo.upsert(
        categoryId: catId,
        amount: 500,
        year: now.year,
        month: now.month,
      );

      // Spend 200
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 200,
        categoryId: catId,
        accountId: accountId,
        date: DateTime(now.year, now.month, now.day, 12),
      );

      final breakdown =
          await txnRepo.expensesByCategoryForMonth(now.year, now.month);
      final budgets = await budgetRepo.getForMonth(now.year, now.month);
      final budget = budgets.firstWhere((b) => b.categoryId == catId);
      final spent = breakdown[catId] ?? 0;

      expect(spent, 200);
      expect(spent < budget.amount, isTrue, reason: 'Should be within budget');
      expect(budget.amount - spent, 300, reason: 'Remaining should be 300');
    });

    test('spending exceeds budget', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final now = DateTime.now();
      final catId = categories.first.id;
      final accountId = accounts.first.id;

      await budgetRepo.upsert(
        categoryId: catId,
        amount: 200,
        year: now.year,
        month: now.month,
      );

      // Spend more than budget
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 150,
          categoryId: catId,
          accountId: accountId,
          date: DateTime(now.year, now.month, now.day));
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 100,
          categoryId: catId,
          accountId: accountId,
          date: DateTime(now.year, now.month, now.day));

      final breakdown =
          await txnRepo.expensesByCategoryForMonth(now.year, now.month);
      final budgets = await budgetRepo.getForMonth(now.year, now.month);
      final budget = budgets.firstWhere((b) => b.categoryId == catId);
      final spent = breakdown[catId]!;

      expect(spent, 250);
      expect(spent > budget.amount, isTrue, reason: 'Should exceed budget');
    });

    test('income does not count against budget', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final now = DateTime.now();
      final catId = categories.first.id;
      final accountId = accounts.first.id;

      await budgetRepo.upsert(
        categoryId: catId,
        amount: 500,
        year: now.year,
        month: now.month,
      );

      // Add income with same category
      await txnRepo.insert(
        type: TransactionType.income,
        amount: 10000,
        categoryId: catId,
        accountId: accountId,
        date: DateTime(now.year, now.month, now.day),
      );

      final breakdown =
          await txnRepo.expensesByCategoryForMonth(now.year, now.month);
      expect(breakdown[catId], isNull,
          reason: 'Income should not count as expense');
    });

    test('expenses in different month do not affect current budget', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final now = DateTime.now();
      final catId = categories.first.id;
      final accountId = accounts.first.id;

      await budgetRepo.upsert(
        categoryId: catId,
        amount: 500,
        year: now.year,
        month: now.month,
      );

      // Add expense in previous month
      final prevMonth = DateTime(now.year, now.month - 1, 15);
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 999,
        categoryId: catId,
        accountId: accountId,
        date: prevMonth,
      );

      final breakdown =
          await txnRepo.expensesByCategoryForMonth(now.year, now.month);
      expect(breakdown[catId], isNull,
          reason: 'Previous month expenses should not count');
    });
  });
}
