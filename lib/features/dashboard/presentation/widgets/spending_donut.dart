import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/extensions/currency_ext.dart';
import 'package:dime_money/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

class SpendingDonut extends ConsumerWidget {
  const SpendingDonut({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(dashboardCategoryBreakdownProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return breakdownAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (breakdown) {
        if (breakdown.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text('No expenses this month',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return categoriesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (categories) {
            final total =
                breakdown.values.fold<double>(0, (a, b) => a + b);

            final sections = breakdown.entries.map((entry) {
              final cat = categories
                  .where((c) => c.id == entry.key)
                  .firstOrNull;
              final color =
                  cat != null ? Color(cat.color) : Colors.grey;
              final pct = (entry.value / total * 100);

              return PieChartSectionData(
                value: entry.value,
                color: color,
                radius: 32,
                title: pct >= 10 ? '${pct.toStringAsFixed(0)}%' : '',
                titleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList();

            // Legend
            final legendItems = breakdown.entries.map((entry) {
              final cat = categories
                  .where((c) => c.id == entry.key)
                  .firstOrNull;
              return (
                name: cat?.name ?? 'Unknown',
                color: cat != null ? Color(cat.color) : Colors.grey,
                amount: entry.value,
              );
            }).toList()
              ..sort((a, b) => b.amount.compareTo(a.amount));

            return Column(
              children: [
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const Gap(12),
                ...legendItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const Gap(8),
                          Expanded(child: Text(item.name)),
                          Text(
                            item.amount.formatCurrency(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),
              ],
            );
          },
        );
      },
    );
  }
}
