import 'dart:math';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';
import 'package:dime_money/features/budgets/data/repositories/budget_repository.dart';
import 'package:dime_money/features/accounts/data/repositories/account_repository.dart';

/// Seeds the database with dummy data for testing.
/// Returns the number of transactions created.
Future<int> seedDummyData(AppDatabase db) async {
  final txnRepo = TransactionRepository(db);
  final budgetRepo = BudgetRepository(db);
  final accountRepo = AccountRepository(db);
  final rng = Random(42); // fixed seed for reproducibility

  // Get existing categories and accounts
  final categories = await db.select(db.categories).get();
  final accounts = await accountRepo.getAll();

  if (categories.isEmpty || accounts.isEmpty) return 0;

  final now = DateTime.now();
  final accountId = accounts.first.id;

  // Add a second account if only one exists
  int secondAccountId = accountId;
  if (accounts.length < 2) {
    secondAccountId = await accountRepo.insert(
      name: 'Bank',
      type: AccountType.bank,
      initialBalance: 1000,
      color: 0xFF42A5F5,
      iconCodePoint: 0xe84f, // Icons.account_balance
    );
  } else {
    secondAccountId = accounts[1].id;
  }

  // Generate 25 transactions over the past 30 days
  final notes = [
    'Coffee',
    'Groceries',
    'Uber ride',
    'Netflix',
    'Lunch',
    'Electricity bill',
    'Gym membership',
    'Books',
    'Gas',
    'Dinner out',
    'Phone bill',
    'Movie tickets',
    'Pharmacy',
    'Clothes',
    'Freelance payment',
    'Salary',
    'Gift',
    'Parking',
    'Snacks',
    'Taxi',
    'Subscription',
    'Rent split',
    'Concert',
    'Online course',
    'Hardware store',
  ];

  int txnCount = 0;

  for (var i = 0; i < 25; i++) {
    final daysAgo = rng.nextInt(30);
    final date = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysAgo));

    TransactionType type;
    int? categoryId;
    int txnAccountId = accountId;
    int? toAccountId;

    if (i < 18) {
      // Expenses
      type = TransactionType.expense;
      categoryId = categories[rng.nextInt(categories.length)].id;
      final amount = (rng.nextDouble() * 195 + 5).roundToDouble(); // $5-$200
      txnAccountId = rng.nextBool() ? accountId : secondAccountId;

      await txnRepo.insert(
        type: type,
        amount: amount,
        categoryId: categoryId,
        accountId: txnAccountId,
        note: notes[i],
        date: date,
      );
    } else if (i < 23) {
      // Income
      type = TransactionType.income;
      categoryId = categories[rng.nextInt(categories.length)].id;
      final amount =
          (rng.nextDouble() * 400 + 100).roundToDouble(); // $100-$500

      await txnRepo.insert(
        type: type,
        amount: amount,
        categoryId: categoryId,
        accountId: txnAccountId,
        note: notes[i],
        date: date,
      );
    } else {
      // Transfers
      type = TransactionType.transfer;
      toAccountId = secondAccountId;
      final amount = (rng.nextDouble() * 200 + 50).roundToDouble(); // $50-$250

      await txnRepo.insert(
        type: type,
        amount: amount,
        accountId: accountId,
        toAccountId: toAccountId,
        note: notes[i],
        date: date,
      );
    }
    txnCount++;
  }

  // Add 2 budgets for current month
  final budgetCategories = categories.take(2).toList();
  for (final cat in budgetCategories) {
    await budgetRepo.upsert(
      categoryId: cat.id,
      amount: (rng.nextDouble() * 300 + 200).roundToDouble(), // $200-$500
      year: now.year,
      month: now.month,
    );
  }

  return txnCount;
}
