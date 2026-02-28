import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/extensions/currency_ext.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:dime_money/features/budgets/presentation/widgets/budget_progress_bar.dart';

class BudgetCard extends ConsumerWidget {
  final Budget budget;
  final double spent;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.spent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final remaining = (budget.amount - spent).clamp(0.0, double.infinity);
    final pct =
        budget.amount > 0 ? (spent / budget.amount * 100).round() : 0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  categoriesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (categories) {
                      final cat = categories
                          .where((c) => c.id == budget.categoryId)
                          .firstOrNull;
                      if (cat == null) return const SizedBox.shrink();
                      return Row(
                        children: [
                          Icon(
                            IconData(cat.iconCodePoint,
                                fontFamily: cat.iconFontFamily),
                            color: Color(cat.color),
                            size: 20,
                          ),
                          const Gap(8),
                          Text(cat.name,
                              style:
                                  Theme.of(context).textTheme.titleSmall),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    '$pct%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
              const Gap(8),
              BudgetProgressBar(spent: spent, limit: budget.amount),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${spent.formatCurrency()} spent',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${remaining.formatCurrency()} left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
