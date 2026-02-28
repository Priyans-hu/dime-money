import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/providers/database_provider.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/features/budgets/data/repositories/budget_repository.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});

final currentMonthBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final now = DateTime.now();
  return ref.watch(budgetRepositoryProvider).watchForMonth(now.year, now.month);
});

/// Budget with spent amount for current month
final budgetWithSpentProvider =
    FutureProvider<List<({Budget budget, double spent})>>((ref) async {
  final now = DateTime.now();
  final budgets =
      await ref.watch(budgetRepositoryProvider).getForMonth(now.year, now.month);
  final expenses = await ref
      .watch(transactionRepositoryProvider)
      .expensesByCategoryForMonth(now.year, now.month);

  return budgets.map((b) {
    return (budget: b, spent: expenses[b.categoryId] ?? 0.0);
  }).toList();
});
