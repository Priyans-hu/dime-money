import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dime_money/core/extensions/date_ext.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

enum DashboardPeriod { daily, weekly, monthly }

final dashboardPeriodProvider =
    StateNotifierProvider<DashboardPeriodNotifier, DashboardPeriod>((ref) {
  return DashboardPeriodNotifier();
});

class DashboardPeriodNotifier extends StateNotifier<DashboardPeriod> {
  DashboardPeriodNotifier() : super(DashboardPeriod.monthly) {
    _load();
  }

  static const _key = 'dashboard_period';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key);
    if (index != null && index < DashboardPeriod.values.length) {
      state = DashboardPeriod.values[index];
    }
  }

  Future<void> set(DashboardPeriod period) async {
    state = period;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, period.index);
  }
}

final dashboardTotalsProvider =
    FutureProvider<({double income, double expense})>((ref) async {
  // Watch transactions stream so this recomputes on any change
  ref.watch(allTransactionsProvider);

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
  // Watch transactions stream so this recomputes on any change
  ref.watch(allTransactionsProvider);

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

  return repo.expensesByCategoryForRange(start, end);
});

final totalBalanceProvider = FutureProvider<double>((ref) async {
  // Watch transactions stream so this recomputes on any change
  ref.watch(allTransactionsProvider);

  final accountRepo = ref.watch(accountRepositoryProvider);
  final accounts = await accountRepo.getAll();
  double total = 0;
  for (final account in accounts) {
    total += await accountRepo.computeBalance(account.id);
  }
  return total;
});
