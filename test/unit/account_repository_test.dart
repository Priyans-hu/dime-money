import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/features/accounts/data/repositories/account_repository.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late AccountRepository accountRepo;
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
    accountRepo = AccountRepository(db);
    txnRepo = TransactionRepository(db);
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('AccountRepository.computeBalance', () {
    test('returns initialBalance when no transactions', () async {
      final accounts = await accountRepo.getAll();
      // Default Cash account has initialBalance 0
      final balance = await accountRepo.computeBalance(accounts.first.id);
      expect(balance, 0);
    });

    test('adds income and subtracts expenses', () async {
      final accounts = await accountRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;

      await txnRepo.insert(
        type: TransactionType.income,
        amount: 1000,
        categoryId: catId,
        accountId: accountId,
        date: DateTime.now(),
      );
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 250,
        categoryId: catId,
        accountId: accountId,
        date: DateTime.now(),
      );

      final balance = await accountRepo.computeBalance(accountId);
      expect(balance, 750); // 0 + 1000 - 250
    });

    test('handles transfers correctly', () async {
      final accounts = await accountRepo.getAll();
      final fromId = accounts.first.id;

      // Create second account
      final toId = await accountRepo.insert(
        name: 'Savings',
        type: AccountType.bank,
        initialBalance: 500,
        color: 0xFF42A5F5,
        iconCodePoint: 0xe84f,
      );

      await txnRepo.insert(
        type: TransactionType.transfer,
        amount: 200,
        accountId: fromId,
        toAccountId: toId,
        date: DateTime.now(),
      );

      final fromBalance = await accountRepo.computeBalance(fromId);
      final toBalance = await accountRepo.computeBalance(toId);

      expect(fromBalance, -200); // 0 - 200 (transfer out)
      expect(toBalance, 700); // 500 + 200 (transfer in)
    });

    test('returns 0 for non-existent account', () async {
      final balance = await accountRepo.computeBalance(99999);
      expect(balance, 0);
    });
  });

  group('AccountRepository.computeTotalBalance', () {
    test('returns sum of all non-archived account balances', () async {
      final accounts = await accountRepo.getAll();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;

      // Create a second account with initial balance
      final secondId = await accountRepo.insert(
        name: 'Savings',
        type: AccountType.bank,
        initialBalance: 500,
        color: 0xFF42A5F5,
        iconCodePoint: 0xe84f,
      );

      // Add transactions
      await txnRepo.insert(
        type: TransactionType.income,
        amount: 1000,
        categoryId: catId,
        accountId: accountId,
        date: DateTime.now(),
      );
      await txnRepo.insert(
        type: TransactionType.expense,
        amount: 250,
        categoryId: catId,
        accountId: secondId,
        date: DateTime.now(),
      );

      final total = await accountRepo.computeTotalBalance();
      // Cash: 0 + 1000 = 1000, Savings: 500 - 250 = 250, Total: 1250
      expect(total, 1250);
    });

    test('excludes archived accounts', () async {
      final archivedId = await accountRepo.insert(
        name: 'Old',
        type: AccountType.bank,
        initialBalance: 9999,
        color: 0xFF42A5F5,
        iconCodePoint: 0xe84f,
      );
      await accountRepo.archive(archivedId);

      final total = await accountRepo.computeTotalBalance();
      // Only Cash account with 0 balance
      expect(total, 0);
    });
  });
}
