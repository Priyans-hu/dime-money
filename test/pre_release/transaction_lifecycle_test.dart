import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';
import 'package:dime_money/features/accounts/data/repositories/account_repository.dart';

/// Pre-release: Full transaction lifecycle tests.
/// Covers income, expense, transfer, edit, delete, and balance verification.
void main() {
  late AppDatabase db;
  late TransactionRepository txnRepo;
  late AccountRepository acctRepo;

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
    acctRepo = AccountRepository(db);
    await db.select(db.categories).get(); // ensure seeds
  });

  tearDown(() => db.close());

  group('Add expense flow', () {
    test('adds expense and balance decreases', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;

      final balanceBefore = await acctRepo.computeBalance(accountId);

      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 150,
        categoryId: catId,
        accountId: accountId,
        date: DateTime.now(),
        note: 'Groceries',
      );

      final balanceAfter = await acctRepo.computeBalance(accountId);
      expect(balanceAfter, balanceBefore - 150);
    });

    test('multiple expenses accumulate', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 50,
          categoryId: catId,
          accountId: accountId,
          date: now);
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 75.50,
          categoryId: catId,
          accountId: accountId,
          date: now);
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 24.50,
          categoryId: catId,
          accountId: accountId,
          date: now);

      final balance = await acctRepo.computeBalance(accountId);
      expect(balance, -150.0); // 0 initial - 50 - 75.50 - 24.50
    });

    test('expense with note persists correctly', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();

      final id = await txnRepo.insert(
        type: TransactionType.expense,
        amount: 42.99,
        categoryId: categories.first.id,
        accountId: accounts.first.id,
        date: DateTime.now(),
        note: 'Coffee at Blue Bottle',
      );

      final txns = await db.select(db.transactions).get();
      final txn = txns.firstWhere((t) => t.id == id);
      expect(txn.note, 'Coffee at Blue Bottle');
      expect(txn.amount, 42.99);
      expect(txn.type, TransactionType.expense);
    });
  });

  group('Add income flow', () {
    test('adds income and balance increases', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;

      await txnRepo.insert(
        type: TransactionType.income,
        amount: 5000,
        categoryId: categories.first.id,
        accountId: accountId,
        date: DateTime.now(),
        note: 'Salary',
      );

      final balance = await acctRepo.computeBalance(accountId);
      expect(balance, 5000);
    });

    test('income to specific account only affects that account', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final primaryId = accounts.first.id;

      // Create second account
      final secondId = await acctRepo.insert(
        name: 'Savings',
        type: AccountType.bank,
        initialBalance: 0,
        color: 0xFF000000,
        iconCodePoint: 0xe000,
      );

      await txnRepo.insert(
        type: TransactionType.income,
        amount: 1000,
        categoryId: categories.first.id,
        accountId: primaryId,
        date: DateTime.now(),
      );

      expect(await acctRepo.computeBalance(primaryId), 1000);
      expect(await acctRepo.computeBalance(secondId), 0);
    });
  });

  group('Transfer flow', () {
    test('transfer moves money between accounts', () async {
      final accounts = await acctRepo.getAll();
      final primaryId = accounts.first.id;

      final secondId = await acctRepo.insert(
        name: 'Bank',
        type: AccountType.bank,
        initialBalance: 0,
        color: 0xFF000000,
        iconCodePoint: 0xe000,
      );

      // Add income first
      final categories = await db.select(db.categories).get();
      await txnRepo.insert(
        type: TransactionType.income,
        amount: 500,
        categoryId: categories.first.id,
        accountId: primaryId,
        date: DateTime.now(),
      );

      // Transfer 200 from primary to second
      await txnRepo.insert(
        type: TransactionType.transfer,
        amount: 200,
        accountId: primaryId,
        toAccountId: secondId,
        date: DateTime.now(),
      );

      expect(await acctRepo.computeBalance(primaryId), 300); // 500 - 200
      expect(await acctRepo.computeBalance(secondId), 200); // 0 + 200
    });

    test('transfer does not affect income/expense totals', () async {
      final accounts = await acctRepo.getAll();
      final primaryId = accounts.first.id;
      final secondId = await acctRepo.insert(
        name: 'Bank',
        type: AccountType.bank,
        color: 0xFF000000,
        iconCodePoint: 0xe000,
      );

      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      await txnRepo.insert(
        type: TransactionType.transfer,
        amount: 1000,
        accountId: primaryId,
        toAccountId: secondId,
        date: now,
      );

      final totals = await txnRepo.totalsForRange(dayStart, dayEnd);
      expect(totals.income, 0);
      expect(totals.expense, 0);
    });
  });

  group('Edit transaction flow', () {
    test('editing amount updates balance', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;

      final id = await txnRepo.insert(
        type: TransactionType.expense,
        amount: 100,
        categoryId: catId,
        accountId: accountId,
        date: DateTime.now(),
      );

      expect(await acctRepo.computeBalance(accountId), -100);

      // Edit: change amount to 50
      final txn = (await db.select(db.transactions).get())
          .firstWhere((t) => t.id == id);
      await txnRepo.update(txn.copyWith(amount: 50));

      expect(await acctRepo.computeBalance(accountId), -50);
    });

    test('changing type from expense to income flips balance', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;

      final id = await txnRepo.insert(
        type: TransactionType.expense,
        amount: 200,
        categoryId: catId,
        accountId: accountId,
        date: DateTime.now(),
      );

      expect(await acctRepo.computeBalance(accountId), -200);

      final txn = (await db.select(db.transactions).get())
          .firstWhere((t) => t.id == id);
      await txnRepo.update(txn.copyWith(type: TransactionType.income));

      expect(await acctRepo.computeBalance(accountId), 200);
    });
  });

  group('Delete transaction flow', () {
    test('deleting expense restores balance', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;

      final id = await txnRepo.insert(
        type: TransactionType.expense,
        amount: 300,
        categoryId: categories.first.id,
        accountId: accountId,
        date: DateTime.now(),
      );

      expect(await acctRepo.computeBalance(accountId), -300);

      await txnRepo.deleteById(id);

      expect(await acctRepo.computeBalance(accountId), 0);
    });

    test('deleting income reduces balance', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;

      final id = await txnRepo.insert(
        type: TransactionType.income,
        amount: 1000,
        categoryId: categories.first.id,
        accountId: accountId,
        date: DateTime.now(),
      );

      expect(await acctRepo.computeBalance(accountId), 1000);

      await txnRepo.deleteById(id);

      expect(await acctRepo.computeBalance(accountId), 0);
    });
  });

  group('Mixed operations scenario', () {
    test('salary → expenses → transfer → delete → final balance', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final cashId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      final bankId = await acctRepo.insert(
        name: 'Bank',
        type: AccountType.bank,
        initialBalance: 1000,
        color: 0xFF000000,
        iconCodePoint: 0xe000,
      );

      // 1. Receive salary in bank
      await txnRepo.insert(
        type: TransactionType.income,
        amount: 5000,
        categoryId: catId,
        accountId: bankId,
        date: now,
        note: 'Salary',
      );
      expect(await acctRepo.computeBalance(bankId), 6000); // 1000 + 5000

      // 2. Pay rent from bank
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 1500,
        categoryId: catId,
        accountId: bankId,
        date: now,
        note: 'Rent',
      );
      expect(await acctRepo.computeBalance(bankId), 4500);

      // 3. Transfer to cash for daily spending
      await txnRepo.insert(
        type: TransactionType.transfer,
        amount: 500,
        accountId: bankId,
        toAccountId: cashId,
        date: now,
      );
      expect(await acctRepo.computeBalance(bankId), 4000);
      expect(await acctRepo.computeBalance(cashId), 500);

      // 4. Daily expenses from cash
      final groceryId = await txnRepo.insert(
        type: TransactionType.expense,
        amount: 120,
        categoryId: catId,
        accountId: cashId,
        date: now,
        note: 'Groceries',
      );
      expect(await acctRepo.computeBalance(cashId), 380);

      // 5. Oops, wrong amount on groceries - delete and re-add
      await txnRepo.deleteById(groceryId);
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 95,
        categoryId: catId,
        accountId: cashId,
        date: now,
        note: 'Groceries (corrected)',
      );
      expect(await acctRepo.computeBalance(cashId), 405);

      // Final totals for today
      final dayStart = DateTime(now.year, now.month, now.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final totals = await txnRepo.totalsForRange(dayStart, dayEnd);
      expect(totals.income, 5000);
      expect(totals.expense, 1595); // 1500 rent + 95 groceries
    });
  });

  group('Search and filtering', () {
    test('search by note finds matching transactions', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 50,
          categoryId: catId,
          accountId: accountId,
          date: now,
          note: 'Coffee shop');
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 30,
          categoryId: catId,
          accountId: accountId,
          date: now,
          note: 'Bus ticket');
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 25,
          categoryId: catId,
          accountId: accountId,
          date: now,
          note: 'Coffee beans');

      final results = await txnRepo.search('Coffee').first;
      expect(results.length, 2);
      expect(results.every((t) => t.note.contains('Coffee')), isTrue);
    });

    test('mostFrequentCategoryId returns most used category', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final now = DateTime.now();

      // Use category 0 three times
      for (int i = 0; i < 3; i++) {
        await txnRepo.insert(
            type: TransactionType.expense,
            amount: 10,
            categoryId: categories[0].id,
            accountId: accountId,
            date: now);
      }
      // Use category 1 once
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 10,
          categoryId: categories[1].id,
          accountId: accountId,
          date: now);

      final mostFrequent = await txnRepo.mostFrequentCategoryId();
      expect(mostFrequent, categories[0].id);
    });

    test('expensesByCategoryForMonth groups correctly', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);

      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 100,
          categoryId: categories[0].id,
          accountId: accountId,
          date: today);
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 200,
          categoryId: categories[0].id,
          accountId: accountId,
          date: today);
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 50,
          categoryId: categories[1].id,
          accountId: accountId,
          date: today);

      final breakdown = await txnRepo.expensesByCategoryForMonth(
          now.year, now.month);
      expect(breakdown[categories[0].id], 300);
      expect(breakdown[categories[1].id], 50);
    });
  });
}
