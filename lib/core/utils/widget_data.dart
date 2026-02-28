import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/constants/enums.dart';

Future<void> updateWidgetData(AppDatabase db) async {
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

  // Compute today's totals
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  double todayIncome = 0, todayExpense = 0;
  for (final t in allTxns) {
    if (!t.date.isBefore(todayStart) && t.date.isBefore(todayEnd)) {
      if (t.type == TransactionType.income) {
        todayIncome += t.amount;
      } else if (t.type == TransactionType.expense) {
        todayExpense += t.amount;
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
  await HomeWidget.saveWidgetData('currency', currency);
  await HomeWidget.updateWidget(
    androidName: 'DimeWidgetProvider',
  );
}
