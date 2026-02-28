import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';

Future<void> updateWidgetData(AppDatabase db) async {
  // Set iOS App Group for shared data
  await HomeWidget.setAppGroupId('group.com.priyanshu.dimeMoney');

  // Compute total balance across all active accounts
  final accounts = await (db.select(db.accounts)
        ..where((a) => a.isArchived.equals(false)))
      .get();

  // Fetch all transactions once
  final allTxns = await db.select(db.transactions).get();

  double totalBalance = 0;
  for (final account in accounts) {
    double bal = account.initialBalance;

    for (final t in allTxns) {
      if (t.type == TransactionType.income && t.accountId == account.id) {
        bal += t.amount;
      } else if (t.type == TransactionType.expense &&
          t.accountId == account.id) {
        bal -= t.amount;
      } else if (t.type == TransactionType.transfer) {
        if (t.toAccountId == account.id) {
          bal += t.amount;
        }
        if (t.accountId == account.id) {
          bal -= t.amount;
        }
      }
    }

    totalBalance += bal;
  }

  // Compute today's, this week's, and this month's totals
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  double todayIncome = 0, todayExpense = 0;
  double weekExpense = 0, monthExpense = 0;

  for (final t in allTxns) {
    if (t.type == TransactionType.expense) {
      // Month (includes today and this week)
      if (!t.date.isBefore(monthStart) && t.date.isBefore(todayEnd)) {
        monthExpense += t.amount;
      }
      // Week
      if (!t.date.isBefore(weekStart) && t.date.isBefore(todayEnd)) {
        weekExpense += t.amount;
      }
      // Today
      if (!t.date.isBefore(todayStart) && t.date.isBefore(todayEnd)) {
        todayExpense += t.amount;
      }
    } else if (t.type == TransactionType.income) {
      if (!t.date.isBefore(todayStart) && t.date.isBefore(todayEnd)) {
        todayIncome += t.amount;
      }
    }
  }

  // Read currency symbol
  final prefs = await SharedPreferences.getInstance();
  final currency = prefs.getString('currency_symbol') ?? '\$';

  // Save to home widget shared data
  await HomeWidget.saveWidgetData('balance', totalBalance.toStringAsFixed(2));
  await HomeWidget.saveWidgetData(
      'today_expense', todayExpense.toStringAsFixed(2));
  await HomeWidget.saveWidgetData(
      'today_income', todayIncome.toStringAsFixed(2));
  await HomeWidget.saveWidgetData(
      'week_expense', weekExpense.toStringAsFixed(2));
  await HomeWidget.saveWidgetData(
      'month_expense', monthExpense.toStringAsFixed(2));
  await HomeWidget.saveWidgetData('currency', currency);

  // Trigger all Android widget providers
  await HomeWidget.updateWidget(androidName: 'DimeSmallWidgetProvider');
  await HomeWidget.updateWidget(androidName: 'DimeMediumWidgetProvider');
  await HomeWidget.updateWidget(androidName: 'DimeLargeWidgetProvider');

  // Trigger iOS widget
  await HomeWidget.updateWidget(iOSName: 'DimeWidget');
}
