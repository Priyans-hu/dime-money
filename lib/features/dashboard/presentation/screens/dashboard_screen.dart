import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:dime_money/features/dashboard/presentation/widgets/balance_header.dart';
import 'package:dime_money/features/dashboard/presentation/widgets/spending_donut.dart';
import 'package:dime_money/features/dashboard/presentation/widgets/period_toggle.dart';
import 'package:dime_money/features/dashboard/presentation/widgets/recent_transactions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dime Money'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardTotalsProvider);
          ref.invalidate(dashboardCategoryBreakdownProvider);
          ref.invalidate(totalBalanceProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            const Gap(8),
            const BalanceHeader(),
            const Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Overview',
                      style: Theme.of(context).textTheme.titleMedium),
                  const PeriodToggle(),
                ],
              ),
            ),
            const Gap(16),
            const SpendingDonut(),
            const Gap(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Recent',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const Gap(8),
            const RecentTransactions(),
          ],
        ),
      ),
    );
  }
}
