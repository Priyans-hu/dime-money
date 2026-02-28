import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:dime_money/core/utils/haptics.dart';
import 'package:dime_money/features/budgets/presentation/providers/budget_provider.dart';
import 'package:dime_money/features/transactions/presentation/providers/transactions_provider.dart';

/// Shows a bottom sheet to create a new budget for the current month.
void showAddBudgetSheet(BuildContext context, WidgetRef ref) {
  final amountController = TextEditingController();
  int? selectedCategoryId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final categoriesAsync = ref.watch(allCategoriesProvider);

      return StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(12),
              Text('New Budget',
                  style: Theme.of(context).textTheme.titleLarge),
              const Gap(16),
              categoriesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const Text('Error'),
                data: (categories) => DropdownButtonFormField<int>(
                  initialValue: selectedCategoryId,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(
                                  IconData(c.iconCodePoint,
                                      fontFamily: c.iconFontFamily),
                                  size: 18,
                                  color: Color(c.color),
                                ),
                                const Gap(8),
                                Text(c.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => selectedCategoryId = v),
                ),
              ),
              const Gap(12),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly Limit',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const Gap(16),
              FilledButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text) ?? 0;
                  if (amount <= 0 || selectedCategoryId == null) return;
                  Haptics.medium();
                  final now = DateTime.now();
                  await ref.read(budgetRepositoryProvider).upsert(
                        categoryId: selectedCategoryId!,
                        amount: amount,
                        year: now.year,
                        month: now.month,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Set Budget'),
              ),
              const Gap(8),
            ],
          ),
        ),
      );
    },
  );
}
