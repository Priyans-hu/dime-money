import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/accounts/data/repositories/account_repository.dart';
import 'package:dime_money/features/categories/data/repositories/category_repository.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';

/// Pre-release: Account and category management tests.
void main() {
  late AppDatabase db;
  late AccountRepository acctRepo;
  late CategoryRepository catRepo;
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
    acctRepo = AccountRepository(db);
    catRepo = CategoryRepository(db);
    txnRepo = TransactionRepository(db);
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('Account management', () {
    test('default Cash account exists on fresh db', () async {
      final accounts = await acctRepo.getAll();
      expect(accounts.length, 1);
      expect(accounts.first.name, 'Cash');
      expect(accounts.first.type, AccountType.cash);
    });

    test('create multiple account types', () async {
      await acctRepo.insert(
        name: 'Bank',
        type: AccountType.bank,
        initialBalance: 5000,
        color: 0xFF2196F3,
        iconCodePoint: 0xe000,
      );
      await acctRepo.insert(
        name: 'Credit Card',
        type: AccountType.card,
        initialBalance: 0,
        color: 0xFFF44336,
        iconCodePoint: 0xe001,
      );

      final accounts = await acctRepo.getAll();
      expect(accounts.length, 3);
      expect(accounts.map((a) => a.type).toSet(),
          {AccountType.cash, AccountType.bank, AccountType.card});
    });

    test('archive hides account from getAll', () async {
      final accounts = await acctRepo.getAll();
      final cashId = accounts.first.id;

      // Create new account first
      await acctRepo.insert(
        name: 'Bank',
        type: AccountType.bank,
        color: 0xFF000000,
        iconCodePoint: 0xe000,
      );

      await acctRepo.archive(cashId);

      final visible = await acctRepo.getAll();
      expect(visible.length, 1);
      expect(visible.first.name, 'Bank');

      // But getById still finds it
      final archived = await acctRepo.getById(cashId);
      expect(archived, isNotNull);
      expect(archived!.isArchived, isTrue);
    });

    test('account with initial balance reflects correctly', () async {
      final id = await acctRepo.insert(
        name: 'Savings',
        type: AccountType.bank,
        initialBalance: 10000,
        color: 0xFF000000,
        iconCodePoint: 0xe000,
      );

      final balance = await acctRepo.computeBalance(id);
      expect(balance, 10000);
    });

    test('balance with mixed transactions', () async {
      final accounts = await acctRepo.getAll();
      final categories = await db.select(db.categories).get();
      final cashId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      // +500 income
      await txnRepo.insert(
          type: TransactionType.income,
          amount: 500,
          categoryId: catId,
          accountId: cashId,
          date: now);
      // -120 expense
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 120,
          categoryId: catId,
          accountId: cashId,
          date: now);
      // -80 expense
      await txnRepo.insert(
          type: TransactionType.expense,
          amount: 80,
          categoryId: catId,
          accountId: cashId,
          date: now);

      final balance = await acctRepo.computeBalance(cashId);
      expect(balance, 300); // 0 + 500 - 120 - 80
    });

    test('transfer between accounts adjusts both balances', () async {
      final accounts = await acctRepo.getAll();
      final cashId = accounts.first.id;

      final bankId = await acctRepo.insert(
        name: 'Bank',
        type: AccountType.bank,
        initialBalance: 5000,
        color: 0xFF000000,
        iconCodePoint: 0xe000,
      );

      await txnRepo.insert(
        type: TransactionType.transfer,
        amount: 2000,
        accountId: bankId,
        toAccountId: cashId,
        date: DateTime.now(),
      );

      expect(await acctRepo.computeBalance(bankId), 3000); // 5000 - 2000
      expect(await acctRepo.computeBalance(cashId), 2000); // 0 + 2000
    });

    test('non-existent account returns 0 balance', () async {
      final balance = await acctRepo.computeBalance(99999);
      expect(balance, 0);
    });
  });

  group('Category management', () {
    test('8 default categories seeded', () async {
      final categories = await catRepo.getAll();
      expect(categories.length, 8);
    });

    test('create custom category', () async {
      final id = await catRepo.insert(
        name: 'Subscriptions',
        iconCodePoint: 0xe157,
        color: 0xFF9C27B0,
      );

      expect(id, greaterThan(0));
      final cat = await catRepo.getById(id);
      expect(cat, isNotNull);
      expect(cat!.name, 'Subscriptions');
    });

    test('update category name', () async {
      final categories = await catRepo.getAll();
      final cat = categories.first;

      await catRepo.update(cat.copyWith(name: 'Renamed Category'));

      final updated = await catRepo.getById(cat.id);
      expect(updated!.name, 'Renamed Category');
    });

    test('delete category', () async {
      final id = await catRepo.insert(
        name: 'Temp',
        iconCodePoint: 0xe000,
        color: 0xFF000000,
      );

      final deleted = await catRepo.deleteById(id);
      expect(deleted, 1);

      final cat = await catRepo.getById(id);
      expect(cat, isNull);
    });

    test('categories ordered by sortOrder', () async {
      await catRepo.insert(
        name: 'Z Category',
        iconCodePoint: 0xe000,
        color: 0xFF000000,
        sortOrder: 100,
      );
      await catRepo.insert(
        name: 'A Category',
        iconCodePoint: 0xe000,
        color: 0xFF000000,
        sortOrder: 1,
      );

      final categories = await catRepo.getAll();
      // Default categories have sortOrder 0, then A (1), then Z (100)
      final customCats = categories.where(
          (c) => c.name == 'A Category' || c.name == 'Z Category').toList();
      expect(customCats.first.name, 'A Category');
      expect(customCats.last.name, 'Z Category');
    });
  });
}
