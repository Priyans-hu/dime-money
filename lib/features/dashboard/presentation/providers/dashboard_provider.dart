import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dime_money/core/extensions/date_ext.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

enum DashboardPeriod { daily, weekly, monthly }

final dashboardPeriodProvider =
    StateProvider<DashboardPeriod>((_) => DashboardPeriod.monthly);

final dashboardTotalsProvider =
    FutureProvider<({double income, double expense})>((ref) async {
  final period = ref.watch(dashboardPeriodProvider);
  final repo = ref.watch(transactionRepositoryProvider);

  final now = DateTime.now();
  late DateTime start;
  late DateTime end;

  switch (period) {
    case DashboardPeriod.daily:
      start = now.startOfDay;
      end = now.endOfDay;
    case DashboardPeriod.weekly:
      start = now.startOfWeek;
      end = now.endOfWeek;
    case DashboardPeriod.monthly:
      start = now.startOfMonth;
      end = now.endOfMonth;
  }

  return repo.totalsForRange(start, end);
});

final dashboardCategoryBreakdownProvider =
    FutureProvider<Map<int, double>>((ref) async {
  final now = DateTime.now();
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.expensesByCategoryForMonth(now.year, now.month);
});

final totalBalanceProvider = FutureProvider<double>((ref) async {
  final accountRepo = ref.watch(accountRepositoryProvider);
  final accounts = await accountRepo.getAll();
  double total = 0;
  for (final account in accounts) {
    total += await accountRepo.computeBalance(account.id);
  }
  return total;
});
