import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/extensions/currency_ext.dart';
import 'package:dime_money/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:dime_money/features/settings/presentation/providers/settings_provider.dart';
import 'package:dime_money/shared/widgets/glass_card.dart';

class BalanceHeader extends ConsumerWidget {
  const BalanceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(totalBalanceProvider);
    final totalsAsync = ref.watch(dashboardTotalsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final incomeEnabled = ref.watch(incomeEnabledProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const Gap(8),
          balanceAsync.when(
            loading: () => const Text('...'),
            error: (_, _) => const Text('--'),
            data: (balance) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currency,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w300,
                      ),
                ),
                const Gap(4),
                Text(
                  balance.formatNumber(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Gap(20),
          totalsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (totals) => Row(
              children: [
                if (incomeEnabled) ...[
                  Expanded(
                    child: _StatChip(
                      label: 'Income',
                      amount: totals.income,
                      color: Colors.green,
                      icon: Icons.south_west,
                      currency: currency,
                    ),
                  ),
                  const Gap(12),
                ],
                Expanded(
                  child: _StatChip(
                    label: 'Expenses',
                    amount: totals.expense,
                    color: Colors.red,
                    icon: Icons.north_east,
                    currency: currency,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final String currency;

  const _StatChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: color)),
                Text(
                  '$currency${amount.formatNumber()}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
