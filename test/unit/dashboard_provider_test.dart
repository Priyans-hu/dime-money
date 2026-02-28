import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/extensions/date_ext.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';
import 'package:dime_money/features/accounts/data/repositories/account_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository txnRepo;
  late AccountRepository accountRepo;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txnRepo = TransactionRepository(db);
    accountRepo = AccountRepository(db);
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('Dashboard totals reactivity (data layer)', () {
    test('totalsForRange updates after inserting a transaction', () async {
      final accounts = await accountRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      // Before: zero
      var totals = await txnRepo.totalsForRange(now.startOfDay, now.endOfDay);
      expect(totals.income, 0);
      expect(totals.expense, 0);

      // Insert expense
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 42,
        categoryId: catId,
        accountId: accountId,
        date: now,
      );

      // After: reflects new expense
      totals = await txnRepo.totalsForRange(now.startOfDay, now.endOfDay);
      expect(totals.expense, 42);
      expect(totals.income, 0);
    });

    test('category breakdown updates after inserting expense', () async {
      final accounts = await accountRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      var breakdown = await txnRepo.expensesByCategoryForRange(
          now.startOfMonth, now.endOfMonth);
      expect(breakdown, isEmpty);

      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 100,
        categoryId: catId,
        accountId: accountId,
        date: now,
      );

      breakdown = await txnRepo.expensesByCategoryForRange(
          now.startOfMonth, now.endOfMonth);
      expect(breakdown[catId], 100);
    });

    test('total balance updates after insert', () async {
      final accounts = await accountRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;

      var balance = await accountRepo.computeBalance(accountId);
      expect(balance, 0);

      await txnRepo.insert(
        type: TransactionType.income,
        amount: 500,
        categoryId: catId,
        accountId: accountId,
        date: DateTime.now(),
      );

      balance = await accountRepo.computeBalance(accountId);
      expect(balance, 500);
    });
  });

  group('Period-aware category breakdown', () {
    test('daily breakdown only includes today\'s expenses', () async {
      final accounts = await accountRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 50,
        categoryId: catId,
        accountId: accountId,
        date: yesterday,
      );
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 30,
        categoryId: catId,
        accountId: accountId,
        date: now,
      );

      final daily = await txnRepo.expensesByCategoryForRange(
          now.startOfDay, now.endOfDay);
      expect(daily[catId], 30);
    });

    test('weekly breakdown includes this week\'s expenses', () async {
      final accounts = await accountRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      // Add expense today (within this week)
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 75,
        categoryId: catId,
        accountId: accountId,
        date: now,
      );

      final weekly = await txnRepo.expensesByCategoryForRange(
          now.startOfWeek, now.endOfWeek);
      expect(weekly[catId], 75);
    });

    test('monthly breakdown includes this month\'s expenses', () async {
      final accounts = await accountRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 200,
        categoryId: catId,
        accountId: accountId,
        date: now,
      );

      final monthly = await txnRepo.expensesByCategoryForRange(
          now.startOfMonth, now.endOfMonth);
      expect(monthly[catId], 200);
    });
  });
}
