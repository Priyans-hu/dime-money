import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/utils/widget_data.dart';
import 'package:dime_money/core/utils/seed_data.dart';
import 'package:dime_money/features/accounts/data/repositories/account_repository.dart';
import 'package:dime_money/features/budgets/data/repositories/budget_repository.dart';
import 'package:dime_money/features/categories/data/repositories/category_repository.dart';
import 'package:dime_money/features/recurring/data/repositories/recurring_repository.dart';
import 'package:dime_money/features/transactions/data/repositories/transaction_repository.dart';

/// Pre-release: Full end-to-end flow simulating a real user scenario.
/// This test mimics a complete month of app usage.
void main() {
  late AppDatabase db;
  late TransactionRepository txnRepo;
  late AccountRepository acctRepo;
  late BudgetRepository budgetRepo;
  late CategoryRepository catRepo;
  late RecurringRepository recurringRepo;
  final savedWidgetData = <String, String>{};

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'saveWidgetData') {
        final args = call.arguments as Map;
        savedWidgetData[args['id'] as String] = args['data'] as String;
      }
      return null;
    });
  });

  setUp(() async {
    savedWidgetData.clear();
    SharedPreferences.setMockInitialValues({'currency_symbol': '₹'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txnRepo = TransactionRepository(db);
    acctRepo = AccountRepository(db);
    budgetRepo = BudgetRepository(db);
    catRepo = CategoryRepository(db);
    recurringRepo = RecurringRepository(db);
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  test('Full month simulation: setup → recurring → spend → budget → widget',
      () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final categories = await catRepo.getAll();
    final accounts = await acctRepo.getAll();
    final cashId = accounts.first.id;
    final foodCatId = categories[0].id;
    final transportCatId = categories[1].id;

    // === Step 1: Create accounts ===
    final bankId = await acctRepo.insert(
      name: 'Bank Account',
      type: AccountType.bank,
      initialBalance: 50000,
      color: 0xFF2196F3,
      iconCodePoint: 0xe000,
    );

    final cardId = await acctRepo.insert(
      name: 'Credit Card',
      type: AccountType.card,
      initialBalance: 0,
      color: 0xFFF44336,
      iconCodePoint: 0xe001,
    );

    expect(await acctRepo.computeBalance(bankId), 50000);

    // === Step 2: Set up recurring rules ===
    // Monthly salary
    await recurringRepo.insert(
      type: TransactionType.income,
      amount: 75000,
      categoryId: categories[2].id,
      accountId: bankId,
      note: 'Salary',
      recurrence: RecurrenceType.monthly,
      startDate: DateTime(now.year, now.month - 2, 1),
    );

    // Daily coffee
    await recurringRepo.insert(
      type: TransactionType.expense,
      amount: 150,
      categoryId: foodCatId,
      accountId: cashId,
      note: 'Morning coffee',
      recurrence: RecurrenceType.daily,
      startDate: DateTime.now().subtract(const Duration(days: 3)),
    );

    // Process recurring
    final generated = await recurringRepo.processRules();
    expect(generated, greaterThan(0));

    // Verify salary was generated
    final allTxns = await db.select(db.transactions).get();
    final salaries =
        allTxns.where((t) => t.note == 'Salary').toList();
    expect(salaries.length, greaterThanOrEqualTo(1));
    expect(salaries.every((t) => t.amount == 75000), isTrue);

    // === Step 3: Set budgets for the month ===
    await budgetRepo.upsert(
      categoryId: foodCatId,
      amount: 8000,
      year: now.year,
      month: now.month,
    );
    await budgetRepo.upsert(
      categoryId: transportCatId,
      amount: 3000,
      year: now.year,
      month: now.month,
    );

    // === Step 4: Add today's expenses ===
    await txnRepo.insert(
      type: TransactionType.expense,
      amount: 500,
      categoryId: foodCatId,
      accountId: cashId,
      date: today,
      note: 'Lunch',
    );
    await txnRepo.insert(
      type: TransactionType.expense,
      amount: 200,
      categoryId: transportCatId,
      accountId: cashId,
      date: today,
      note: 'Uber',
    );
    await txnRepo.insert(
      type: TransactionType.expense,
      amount: 2500,
      categoryId: categories[3].id,
      accountId: cardId,
      date: today,
      note: 'Shoes',
    );

    // === Step 5: Transfer money bank → cash ===
    await txnRepo.insert(
      type: TransactionType.transfer,
      amount: 5000,
      accountId: bankId,
      toAccountId: cashId,
      date: today,
    );

    // === Step 6: Verify balances ===
    final currentTxns = await db.select(db.transactions).get();
    final coffees =
        currentTxns.where((t) => t.note == 'Morning coffee').length;
    final cashBalance = await acctRepo.computeBalance(cashId);
    // Cash: 0 + 5000 (transfer in) - 500 (lunch) - 200 (uber) - (coffees * 150)
    expect(cashBalance, 4300 - (coffees * 150));

    final cardBalance = await acctRepo.computeBalance(cardId);
    expect(cardBalance, -2500); // 0 - 2500 shoes

    // === Step 7: Verify budget tracking ===
    final breakdown =
        await txnRepo.expensesByCategoryForMonth(now.year, now.month);
    final foodSpent = breakdown[foodCatId] ?? 0;
    // Count coffees that fall within current month only
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final coffeesThisMonth = currentTxns
        .where((t) =>
            t.note == 'Morning coffee' &&
            !t.date.isBefore(monthStart) &&
            !t.date.isAfter(monthEnd))
        .length;
    // Food: 500 (lunch) + coffeesThisMonth * 150 (morning coffee)
    expect(foodSpent, 500 + (coffeesThisMonth * 150));

    final transportSpent = breakdown[transportCatId] ?? 0;
    expect(transportSpent, 200);

    final foodBudgets = await budgetRepo.getForMonth(now.year, now.month);
    final foodBudget =
        foodBudgets.firstWhere((b) => b.categoryId == foodCatId);
    expect(foodBudget.amount, 8000);
    expect(foodSpent < foodBudget.amount, isTrue);

    // === Step 8: Verify today's totals ===
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final totals = await txnRepo.totalsForRange(dayStart, dayEnd);
    // Today's expenses: 500 (lunch) + 200 (uber) + 2500 (shoes) + today's coffees
    final todayCoffees = currentTxns
        .where((t) =>
            t.note == 'Morning coffee' &&
            !t.date.isBefore(dayStart) &&
            t.date.isBefore(dayEnd))
        .length;
    expect(totals.expense, 3200 + (todayCoffees * 150));

    // === Step 9: Verify widget data ===
    await updateWidgetData(db);
    expect(savedWidgetData['currency'], '₹');
    expect(double.parse(savedWidgetData['today_expense']!),
        closeTo(3200 + (todayCoffees * 150), 0.01));
    expect(savedWidgetData['balance'], isNotNull);

    // === Step 10: Edit a transaction ===
    final txnList = await db.select(db.transactions).get();
    final lunchTxn = txnList.firstWhere((t) => t.note == 'Lunch');
    await txnRepo.update(lunchTxn.copyWith(amount: 350, note: 'Light lunch'));

    final updatedTotals = await txnRepo.totalsForRange(dayStart, dayEnd);
    // 350 (edited lunch) + 200 (uber) + 2500 (shoes) + todayCoffees * 150
    expect(updatedTotals.expense, 3050 + (todayCoffees * 150));

    // === Step 11: Delete a transaction ===
    final uberTxn = txnList.firstWhere((t) => t.note == 'Uber');
    await txnRepo.deleteById(uberTxn.id);

    final finalTotals = await txnRepo.totalsForRange(dayStart, dayEnd);
    // 350 (lunch) + 2500 (shoes) + todayCoffees * 150
    expect(finalTotals.expense, 2850 + (todayCoffees * 150));
  });

  test('Seed dummy data + widget data pipeline works end-to-end', () async {
    // Seed realistic data
    final count = await seedDummyData(db);
    expect(count, 25);

    // Update widget data
    await updateWidgetData(db);

    // Verify all data keys are present and valid
    expect(savedWidgetData['balance'], isNotNull);
    expect(savedWidgetData['today_expense'], isNotNull);
    expect(savedWidgetData['today_income'], isNotNull);
    expect(savedWidgetData['week_expense'], isNotNull);
    expect(savedWidgetData['month_expense'], isNotNull);
    expect(savedWidgetData['currency'], '₹');

    // All values should be valid numbers
    for (final key in [
      'balance',
      'today_expense',
      'today_income',
      'week_expense',
      'month_expense'
    ]) {
      expect(double.tryParse(savedWidgetData[key]!), isNotNull,
          reason: '$key should be a valid number');
    }

    // Verify accounts exist
    final accounts = await acctRepo.getAll();
    expect(accounts.length, 2); // Cash + Bank from seed

    // Verify budgets exist
    final now = DateTime.now();
    final budgets = await budgetRepo.getForMonth(now.year, now.month);
    expect(budgets.length, 2);

    // Verify transaction count
    final txns = await db.select(db.transactions).get();
    expect(txns.length, 25);
  });
}
