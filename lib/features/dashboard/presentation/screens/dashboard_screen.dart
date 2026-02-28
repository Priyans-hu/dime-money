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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardTotalsProvider);
          ref.invalidate(dashboardCategoryBreakdownProvider);
          ref.invalidate(totalBalanceProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              centerTitle: false,
              toolbarHeight: 64,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const Text('Dime Money'),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverList.list(
                children: [
                  const Gap(4),
                  const BalanceHeader(),
                  const Gap(24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Spending',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const PeriodToggle(),
                      ],
                    ),
                  ),
                  const Gap(16),
                  const SpendingDonut(),
                  const Gap(24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Recent',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const Gap(8),
                  const RecentTransactions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
