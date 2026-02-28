import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/database/app_database.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/budgets/presentation/providers/budget_provider.dart';
import 'package:dime_money/features/budgets/presentation/widgets/budget_card.dart';
import 'package:dime_money/shared/widgets/empty_state.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetDataAsync = ref.watch(budgetWithSpentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: budgetDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No budgets set',
              subtitle: 'Tap + to create a monthly budget',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return BudgetCard(
                budget: item.budget,
                spent: item.spent,
                onTap: () => _showEditBudget(context, ref, item.budget),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditBudget(BuildContext context, WidgetRef ref, Budget budget) {
    final amountController =
        TextEditingController(text: budget.amount.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Budget',
                style: Theme.of(context).textTheme.titleLarge),
            const Gap(16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly Limit',
                prefixIcon: Icon(Icons.attach_money),
              ),
              autofocus: true,
            ),
            const Gap(16),
            Row(
              children: [
                TextButton(
                  onPressed: () async {
                    Haptics.medium();
                    await ref
                        .read(budgetRepositoryProvider)
                        .deleteById(budget.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) return;
                    Haptics.medium();
                    await ref.read(budgetRepositoryProvider).upsert(
                          categoryId: budget.categoryId,
                          amount: amount,
                          year: budget.year,
                          month: budget.month,
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}
