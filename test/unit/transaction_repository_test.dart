import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('expensesByCategoryForRange', () {
    test('returns empty map when no transactions exist', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final result = await repo.expensesByCategoryForRange(start, end);
      expect(result, isEmpty);
    });

    test('sums expenses by category within date range', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final catId = categories.first.id;
      final accountId = accounts.first.id;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Add 2 expenses for same category today
      await repo.insert(
        type: TransactionType.expense,
        amount: 50,
        categoryId: catId,
        accountId: accountId,
        date: today,
      );
      await repo.insert(
        type: TransactionType.expense,
        amount: 30,
        categoryId: catId,
        accountId: accountId,
        date: today,
      );

      final result = await repo.expensesByCategoryForRange(
        today,
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      expect(result[catId], 80);
    });

    test('excludes income transactions', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final catId = categories.first.id;
      final accountId = accounts.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await repo.insert(
        type: TransactionType.income,
        amount: 100,
        categoryId: catId,
        accountId: accountId,
        date: today,
      );

      final result = await repo.expensesByCategoryForRange(
        today,
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      expect(result, isEmpty);
    });

    test('excludes transactions outside date range', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final catId = categories.first.id;
      final accountId = accounts.first.id;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      await repo.insert(
        type: TransactionType.expense,
        amount: 50,
        categoryId: catId,
        accountId: accountId,
        date: yesterday,
      );

      // Query only today
      final result = await repo.expensesByCategoryForRange(
        today,
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      expect(result, isEmpty);
    });

    test('groups multiple categories correctly', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final accountId = accounts.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await repo.insert(
        type: TransactionType.expense,
        amount: 25,
        categoryId: categories[0].id,
        accountId: accountId,
        date: today,
      );
      await repo.insert(
        type: TransactionType.expense,
        amount: 75,
        categoryId: categories[1].id,
        accountId: accountId,
        date: today,
      );

      final result = await repo.expensesByCategoryForRange(
        today,
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      expect(result.length, 2);
      expect(result[categories[0].id], 25);
      expect(result[categories[1].id], 75);
    });
  });

  group('totalsForRange', () {
    test('returns zero totals when no transactions', () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final result = await repo.totalsForRange(start, end);
      expect(result.income, 0);
      expect(result.expense, 0);
    });

    test('correctly separates income and expense', () async {
      final categories = await db.select(db.categories).get();
      final accounts = await db.select(db.accounts).get();
      final catId = categories.first.id;
      final accountId = accounts.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await repo.insert(
        type: TransactionType.expense,
        amount: 100,
        categoryId: catId,
        accountId: accountId,
        date: today,
      );
      await repo.insert(
        type: TransactionType.income,
        amount: 200,
        categoryId: catId,
        accountId: accountId,
        date: today,
      );

      final result = await repo.totalsForRange(
        today,
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      expect(result.expense, 100);
      expect(result.income, 200);
    });

    test('ignores transfers in totals', () async {
      final accounts = await db.select(db.accounts).get();
      final accountId = accounts.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await repo.insert(
        type: TransactionType.transfer,
        amount: 500,
        accountId: accountId,
        toAccountId: accountId,
        date: today,
      );

      final result = await repo.totalsForRange(
        today,
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      expect(result.income, 0);
      expect(result.expense, 0);
    });
  });

  group('CRUD operations', () {
    test('insert returns an id > 0', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      final id = await repo.insert(
        type: TransactionType.expense,
        amount: 42,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        date: DateTime.now(),
      );

      expect(id, greaterThan(0));
    });

    test('deleteById removes the transaction', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      final id = await repo.insert(
        type: TransactionType.expense,
        amount: 42,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        date: DateTime.now(),
      );

      final deleted = await repo.deleteById(id);
      expect(deleted, 1);

      final all = await db.select(db.transactions).get();
      expect(all, isEmpty);
    });

    test('watchAll emits updated list after insert', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();

      final stream = repo.watchAll();

      // Should start empty
      expect(await stream.first, isEmpty);

      await repo.insert(
        type: TransactionType.expense,
        amount: 10,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        date: DateTime.now(),
      );

      // Next emission should have 1 item
      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.amount, 10);
    });
  });
}
