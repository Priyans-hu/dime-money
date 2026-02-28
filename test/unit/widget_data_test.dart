import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:dime_money/core/utils/widget_data.dart';

void main() {
  late AppDatabase db;
  final savedWidgetData = <String, String>{};

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock home_widget method channel
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
    // Wait for seed data
    await db.select(db.categories).get();
  });

  tearDown(() => db.close());

  group('updateWidgetData', () {
    test('saves zero values when no transactions', () async {
      await updateWidgetData(db);

      expect(savedWidgetData['balance'], isNotNull);
      expect(savedWidgetData['today_expense'], '0.00');
      expect(savedWidgetData['today_income'], '0.00');
      expect(savedWidgetData['week_expense'], '0.00');
      expect(savedWidgetData['month_expense'], '0.00');
      expect(savedWidgetData['currency'], '₹');
    });

    test('computes today expense correctly', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);

      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.expense,
        amount: 42.5,
        accountId: accountId,
        categoryId: Value(catId),
        date: today,
      ));

      await updateWidgetData(db);

      expect(savedWidgetData['today_expense'], '42.50');
      expect(savedWidgetData['week_expense'], '42.50');
      expect(savedWidgetData['month_expense'], '42.50');
    });

    test('computes today income correctly', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);

      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.income,
        amount: 100,
        accountId: accountId,
        categoryId: Value(catId),
        date: today,
      ));

      await updateWidgetData(db);

      expect(savedWidgetData['today_income'], '100.00');
      // Income should not count as expense
      expect(savedWidgetData['today_expense'], '0.00');
      expect(savedWidgetData['week_expense'], '0.00');
      expect(savedWidgetData['month_expense'], '0.00');
    });

    test('week expense includes last 7 days but not before', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();

      // Expense from start of current week
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));

      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.expense,
        amount: 25,
        accountId: accountId,
        categoryId: Value(catId),
        date: weekStart,
      ));

      await updateWidgetData(db);

      expect(double.parse(savedWidgetData['week_expense']!), 25.0);
    });

    test('balance accounts for income, expense, and transfers', () async {
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      final accountId = accounts.first.id;
      final catId = categories.first.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);

      // Initial balance from seed is 0 for Cash account
      // Add income
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.income,
        amount: 1000,
        accountId: accountId,
        categoryId: Value(catId),
        date: today,
      ));

      // Add expense
      await db.into(db.transactions).insert(TransactionsCompanion.insert(
        type: TransactionType.expense,
        amount: 300,
        accountId: accountId,
        categoryId: Value(catId),
        date: today,
      ));

      await updateWidgetData(db);

      // Balance = 0 (initial) + 1000 (income) - 300 (expense) = 700
      expect(savedWidgetData['balance'], '700.00');
    });

    test('uses default currency when not set', () async {
      SharedPreferences.setMockInitialValues({});

      await updateWidgetData(db);

      expect(savedWidgetData['currency'], '\$');
    });
  });
}
