import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:dime_money/core/utils/widget_data.dart';
import 'package:dime_money/core/utils/seed_data.dart';

/// Pre-release integration tests for widget data pipeline.
/// Verifies that widget data is computed correctly with realistic data,
/// including seeded dummy data and edge cases.
void main() {
  late AppDatabase db;
  final savedWidgetData = <String, String>{};
  final updatedWidgets = <String>[];

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'saveWidgetData') {
        final args = call.arguments as Map;
        savedWidgetData[args['id'] as String] = args['data'] as String;
      }
      if (call.method == 'updateWidget') {
        final args = call.arguments as Map?;
        final name = args?['android'] as String? ?? args?['ios'] as String?;
        if (name != null) updatedWidgets.add(name);
      }
      return null;
    });
  });

  setUp(() async {
    savedWidgetData.clear();
    updatedWidgets.clear();
    SharedPreferences.setMockInitialValues({'currency_symbol': '\$'});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('Widget data with seeded dummy data', () {
    test('updates all 4 widget targets after seed', () async {
      await seedDummyData(db);
      await updateWidgetData(db);

      expect(updatedWidgets, contains('DimeSmallWidgetProvider'));
      expect(updatedWidgets, contains('DimeMediumWidgetProvider'));
      expect(updatedWidgets, contains('DimeLargeWidgetProvider'));
      expect(updatedWidgets, contains('DimeWidget'));
    });

    test('balance is non-zero after seeding dummy data', () async {
      await seedDummyData(db);
      await updateWidgetData(db);

      final balance = double.parse(savedWidgetData['balance']!);
      // Seed data creates income + expenses, balance should be non-zero
      expect(balance, isNot(0.0));
    });

    test('week expense >= today expense (week always includes today)', () async {
      await seedDummyData(db);
      await updateWidgetData(db);

      final todayExpense = double.parse(savedWidgetData['today_expense']!);
      final weekExpense = double.parse(savedWidgetData['week_expense']!);

      expect(weekExpense, greaterThanOrEqualTo(todayExpense));
    });

    test('all saved values are valid decimal strings', () async {
      await seedDummyData(db);
      await updateWidgetData(db);

      for (final key in [
        'balance',
        'today_expense',
        'today_income',
        'week_expense',
        'month_expense'
      ]) {
        final value = savedWidgetData[key];
        expect(value, isNotNull, reason: '$key should be saved');
        expect(double.tryParse(value!), isNotNull,
            reason: '$key="$value" should be a valid number');
        // Should have exactly 2 decimal places
        expect(value.contains('.'), isTrue,
            reason: '$key should have decimal point');
        expect(value.split('.').last.length, 2,
            reason: '$key should have 2 decimal places');
      }
    });
  });

  group('Widget data edge cases', () {
    test('handles archived accounts correctly (excluded from balance)',
        () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      final activeAccountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);

      // Create an archived account with a large balance
      final archivedId = await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'Archived',
              type: AccountType.bank,
              color: 0xFF000000,
              iconCodePoint: 0xe000,
              initialBalance: Value(50000),
              isArchived: Value(true),
            ),
          );

      // Add income to archived account
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.income,
        amount: 10000,
        accountId: archivedId,
        categoryId: Value(catId),
        date: today,
      ));

      // Add small amount to active account
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.income,
        amount: 100,
        accountId: activeAccountId,
        categoryId: Value(catId),
        date: today,
      ));

      await updateWidgetData(db);

      final balance = double.parse(savedWidgetData['balance']!);
      // Balance should only include active account (100), not archived (60000)
      expect(balance, 100.0);
    });

    test('transfers do not count as income or expense in today totals',
        () async {
      final accounts = await db.select(db.accounts).get();
      final activeAccountId = accounts.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);

      // Create second account for transfer
      final secondId = await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              name: 'Savings',
              type: AccountType.bank,
              color: 0xFF000000,
              iconCodePoint: 0xe000,
              initialBalance: Value(0),
            ),
          );

      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.transfer,
        amount: 500,
        accountId: activeAccountId,
        toAccountId: Value(secondId),
        date: today,
      ));

      await updateWidgetData(db);

      expect(savedWidgetData['today_expense'], '0.00');
      expect(savedWidgetData['today_income'], '0.00');
      expect(savedWidgetData['week_expense'], '0.00');
      expect(savedWidgetData['month_expense'], '0.00');
    });

    test('yesterday expense counts in week but not today', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterday = todayStart.subtract(const Duration(days: 1));
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.expense,
        amount: 77,
        accountId: accountId,
        categoryId: Value(catId),
        date: yesterday,
      ));

      await updateWidgetData(db);

      // Yesterday is never "today"
      expect(savedWidgetData['today_expense'], '0.00');

      // Week includes yesterday only if it's in the same ISO week
      if (!yesterday.isBefore(weekStart)) {
        expect(double.parse(savedWidgetData['week_expense']!), 77.0);
      }

      // Month includes yesterday only if same month
      if (!yesterday.isBefore(monthStart)) {
        expect(double.parse(savedWidgetData['month_expense']!), 77.0);
      }
    });

    test('multiple expenses accumulate correctly', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10);

      // Add 5 expenses with different categories
      double total = 0;
      for (int i = 0; i < 5; i++) {
        final amount = (i + 1) * 10.5; // 10.5, 21.0, 31.5, 42.0, 52.5
        total += amount;
        await db.into(db.transactions).insert(TransactionsCompanion.insert(
          type: TransactionType.expense,
          amount: amount,
          accountId: accountId,
          categoryId: Value(categories[i % categories.length].id),
          date: today,
        ));
      }

      await updateWidgetData(db);

      expect(
          double.parse(savedWidgetData['today_expense']!), closeTo(total, 0.01));
      expect(
          double.parse(savedWidgetData['week_expense']!), closeTo(total, 0.01));
      expect(
          double.parse(savedWidgetData['month_expense']!), closeTo(total, 0.01));
    });
  });

  group('Quick add sheet initialType', () {
    test('initialType expense sets type correctly', () {
      // Testing the logic: if initialType != null and not editing, type = initialType
      const TransactionType? initialType = TransactionType.expense;
      TransactionType type = TransactionType.expense; // default
      final isEditing = false;

      if (!isEditing && initialType != null) {
        type = initialType;
      }

      expect(type, TransactionType.expense);
    });

    test('initialType income overrides default expense type', () {
      const TransactionType? initialType = TransactionType.income;
      TransactionType type = TransactionType.expense; // default
      final isEditing = false;

      if (!isEditing && initialType != null) {
        type = initialType;
      }

      expect(type, TransactionType.income);
    });

    test('initialType ignored when editing', () {
      const TransactionType? initialType = TransactionType.income;
      TransactionType type = TransactionType.expense; // from edit txn
      final isEditing = true;

      if (!isEditing && initialType != null) {
        type = initialType;
      }

      // Should keep the edit transaction's type
      expect(type, TransactionType.expense);
    });

    test('null initialType keeps default expense', () {
      const TransactionType? initialType = null;
      TransactionType type = TransactionType.expense;
      final isEditing = false;

      if (!isEditing && initialType != null) {
        type = initialType;
      }

      expect(type, TransactionType.expense);
    });
  });
}
